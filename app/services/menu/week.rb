module Menu
  # Assemble une semaine : planning des 7 jours, plats dans leurs rôles,
  # liste de courses et déroulé de la session de batch cooking.
  class Week
    Day = Struct.new(:index, :name, :breakfast, :lunch, :snack, :dinner,
                     :lunch_role, :dinner_role, :from_freezer, :revival, :totals,
                     keyword_init: true)
    Line = Struct.new(:ingredient, :grams, :note, keyword_init: true)
    Step = Struct.new(:time, :duration, :title, :actions, keyword_init: true)

    attr_reader :target, :number, :season

    def initialize(target, number)
      @target = target
      @number = number
      @dishes = Dish.for_week(number).includes(dish_components: :ingredient).to_a
      @season = @dishes.first&.season
    end

    # Le plat qui se conserve le moins bien prend le rôle F : 4 portions,
    # consommées du lundi au jeudi. Les deux autres font 5 portions et
    # passent partiellement au congélateur.
    def roles
      @roles ||= begin
        ordered = @dishes.sort_by { |d| [ d.freezable? ? 1 : 0, d.letter ] }
        { "F" => ordered[0], "A" => ordered[1], "B" => ordered[2] }.compact
      end
    end

    def portions = @portions ||= RolePortion.map

    def days
      @days ||= WeekPattern.all.map do |pattern|
        breakfast = fixed_meal("breakfast", pattern.breakfast_position)
        snack     = fixed_meal("snack",     pattern.snack_position)
        lunch     = resolved(roles[pattern.lunch_role])
        dinner    = resolved(roles[pattern.dinner_role])
        totals = [ breakfast, snack, lunch, dinner ].compact
                   .reduce(Nutrition::Macros.zero) { |a, r| a + r.macros }

        Day.new(index: pattern.day_index, name: pattern.day_name,
                breakfast: breakfast, lunch: lunch, snack: snack, dinner: dinner,
                lunch_role: pattern.lunch_role, dinner_role: pattern.dinner_role,
                from_freezer: pattern.from_freezer?, revival: pattern.revival, totals: totals)
      end
    end

    def averages
      totals = days.map(&:totals)
      return Nutrition::Macros.zero if totals.empty?
      totals.reduce(Nutrition::Macros.zero) { |a, t| a + t } * (1.0 / totals.size)
    end

    def shortfalls
      minimums = target.macro_minimums
      days.reject { |d| d.totals.meets?(minimums) }
    end

    # Quantités pour une personne sur sept jours : les trois plats multipliés
    # par leurs portions, plus les sept petits-déjeuners et sept collations.
    def shopping_list
      totals = Hash.new(0.0)
      roles.each do |role, dish|
        next unless (r = resolved(dish))
        r.grams.each { |key, g| totals[key] += g.to_f * portions.fetch(role, 1) }
      end
      WeekPattern.all.each do |pattern|
        [ fixed_meal("breakfast", pattern.breakfast_position),
          fixed_meal("snack", pattern.snack_position) ].compact.each do |meal|
          meal.grams.each { |key, g| totals[key] += g.to_f }
        end
      end

      purchased = Hash.new(0.0)
      totals.each do |key, grams|
        ingredient = ingredients[key] or next
        bought = ingredient.purchase_ingredient || ingredient
        purchased[bought.key] += grams * ingredient.purchase_factor.to_f
      end

      purchased.sort_by { |_, g| -g }.each_with_object({}) do |(key, grams), grouped|
        ingredient = ingredients[key]
        step = ingredient.rounding_step
        rounded = (grams / step).ceil * step
        note = if ingredient.canned_factor.present?
          drained = ((rounded * ingredient.canned_factor.to_f) / 10).round * 10
          "≈ #{drained} g égouttés en conserve"
        end
        (grouped[ingredient.aisle] ||= []) << Line.new(ingredient: ingredient, grams: rounded, note: note)
      end
    end

    def batch_plan
      soaks = collect(:soak_time)
      cooks = collect(:long_cook_time)
      oven  = roles.values.select { |d| d.equipment.to_s.include?("Four") }
      seitan = roles.values.any? { |d| d.dish_components.any? { |c| c.ingredient.key == "seitan" } }

      steps = []
      if soaks.any? || seitan
        actions = []
        actions << "Mettre à tremper : #{soaks.map { |i, t| "#{i.name} (#{t})" }.join(', ')}." if soaks.any?
        actions << "Pétrir et cuire le seitan (30 min de cuisson, il se conserve 5 jours au frais)." if seitan
        steps << Step.new(time: "La veille", duration: "10 min", title: "Trempages & seitan", actions: actions)
      end

      opening = [ oven.any? ? "Préchauffer le four à 210 °C." : "Sortir tous les ingrédients et la balance." ]
      opening << "Lancer les cuissons longues, toutes en parallèle : #{cooks.map { |i, t| "#{i.name} (#{t})" }.join(', ')}." if cooks.any?
      opening << "Remplir une bouilloire : l'eau bouillante fait gagner 10 min sur chaque cuisson."
      steps << Step.new(time: "0:00 → 0:15", duration: "15 min", title: "Mise en route", actions: opening)

      steps << Step.new(time: "0:15 → 0:45", duration: "30 min", title: "Découpe groupée", actions: [
        "Tailler EN UNE SEULE FOIS les légumes des trois plats, en séparant par plat dans des saladiers.",
        "Émincer d'un coup l'ensemble des oignons, de l'ail et du gingembre de la semaine : c'est le geste qui fait gagner le plus de temps.",
        "Presser les tofus sous un poids pendant que vous découpez." ])

      first = oven.first || roles.values.first
      steps << if oven.any?
        Step.new(time: "0:45 → 1:20", duration: "35 min", title: "Au four : #{first.name}", actions: [
          "Enfourner les éléments à rôtir de « #{first.name} » : étaler en une seule couche, sur deux plaques si nécessaire.",
          "Le four travaille seul : enchaîner immédiatement sur le plat suivant.",
          "Torréfier les graines et oléagineux de la semaine 6 min à 160 °C à la fin de la fournée." ])
      else
        Step.new(time: "0:45 → 1:20", duration: "35 min", title: "Plat 1 : #{first.name}", actions: [
          "Lancer la cuisson selon la recette.",
          "Torréfier à sec les graines et oléagineux de la semaine pendant ce temps." ])
      end

      rest = roles.values.reject { |d| d.id == first.id }
      steps << Step.new(time: "1:20 → 2:00", duration: "40 min", title: "Plat 2 : #{rest[0]&.name}", actions: [
        "Suivre la recette. Utiliser les légumineuses et céréales déjà cuites en début de session.",
        "Goûter et saler en fin de cuisson, jamais au début : les plats de batch se concentrent en refroidissant." ])
      steps << Step.new(time: "2:00 → 2:35", duration: "35 min", title: "Plat 3 : #{rest[1]&.name}", actions: [
        "Dernier plat, celui qui demande le moins de cuisson passive.",
        "Préparer en parallèle les sauces et vinaigrettes de la semaine, à stocker en pots séparés." ])
      steps << Step.new(time: "2:35 → 3:00", duration: "25 min", title: "Refroidissement, pesée & étiquetage", actions: [
        "Étaler les plats sur des plaques froides 15 min : refroidir vite est la première règle de sécurité alimentaire (moins de 2 h entre 63 °C et 10 °C).",
        "Peser les portions à la balance : #{portions['F']} portions du plat frais, #{portions['A']} et #{portions['B']} pour les deux autres. C'est la pesée, pas la recette, qui garantit les macros.",
        "Étiqueter chaque boîte : nom du plat, date, et « FRIGO » ou « CONGÉL ».",
        "Mettre au congélateur les portions des trois derniers jours de la semaine, et les garnitures croquantes dans des bocaux à part." ])
      steps
    end

    private

    def collect(attribute)
      roles.values.flat_map { |d| d.dish_components.map(&:ingredient) }
        .select { |i| i.public_send(attribute).present? }
        .uniq(&:key)
        .map { |i| [ i, i.public_send(attribute) ] }
    end

    def resolved(dish)
      return nil unless dish
      @resolved ||= ResolvedDish.where(nutrition_target: target).includes(:dish).index_by(&:dish_id)
      @resolved[dish.id]
    end

    def fixed_meal(kind, position)
      @fixed ||= ResolvedFixedMeal.where(nutrition_target: target, season: season)
                                 .includes(:fixed_meal).to_a
      @fixed.detect { |r| r.fixed_meal.kind == kind && r.fixed_meal.position == position }
    end

    def ingredients = @ingredients ||= Ingredient.all.index_by(&:key)
  end
end
