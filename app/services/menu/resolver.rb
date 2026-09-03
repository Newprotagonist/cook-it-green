module Menu
  # Applique le solveur à une recette pour une cible donnée et produit
  # les attributs prêts à être persistés.
  class Resolver
    attr_reader :target, :settings

    def initialize(target, settings: NutritionSetting.current)
      @target = target
      @settings = settings
    end

    def resolve_dish(dish)
      slot_target = target.slot_target("dish")
      base_grams  = dish.base_components.each_with_object(Hash.new(0.0)) do |c, h|
        h[c.ingredient.key] += c.grams.to_f
      end
      levers = dish.lever_components.map { |c| Nutrition::Solver::Lever.from(c.ingredient) }
      build(base_grams, levers, slot_target, settings.solver_step_dishes)
        .merge(dish_id: dish.id, nutrition_target_id: target.id)
    end

    def resolve_fixed_meal(meal, season)
      slot_target = target.slot_target(meal.slot)
      base_grams  = Hash.new(0.0)
      levers = []

      meal.fixed_meal_components.each do |component|
        ingredient = component.ingredient_for(season)
        next if ingredient.nil?

        if component.role == "lever"
          levers << Nutrition::Solver::Lever.from(ingredient)
        else
          base_grams[ingredient.key] += component.grams.to_f
        end
      end

      build(base_grams, levers, slot_target, settings.solver_step_fixed_meals)
        .merge(fixed_meal_id: meal.id, nutrition_target_id: target.id, season: season)
    end

    private

    def build(base_grams, levers, slot_target, step)
      base_macros = macros_for(base_grams)
      solver = Nutrition::Solver.new(step: step,
                                     undershoot_penalty: settings.undershoot_penalty)
      result = solver.solve(base: base_macros, levers: levers, target: slot_target)

      grams = base_grams.dup
      result.grams.each { |key, g| grams[key] = grams.fetch(key, 0.0) + g }
      total = macros_for(grams)

      {
        grams: grams.transform_values { |g| g.round(1) },
        kcal: total.kcal.round(2), protein: total.protein.round(2),
        lipid: total.lipid.round(2), carb: total.carb.round(2), fiber: total.fiber.round(2),
        protein_deviation: (total.protein - slot_target[:protein]).round(2),
        lipid_deviation:   (total.lipid   - slot_target[:lipid]).round(2),
        carb_deviation:    (total.carb    - slot_target[:carb]).round(2)
      }
    end

    def macros_for(grams)
      grams.reduce(Nutrition::Macros.zero) do |acc, (key, g)|
        acc + ingredients.fetch(key).macros_for(g)
      end
    end

    def ingredients
      @ingredients ||= Ingredient.all.index_by(&:key)
    end
  end
end
