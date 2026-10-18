require "test_helper"

# L'invariant central du projet : quelle que soit la cible, chaque journée de
# l'année atteint les quatre minimums. C'est la seule garantie qui compte,
# et elle dépend de 62 bornes de grammage, 6 lignes de répartition et
# 7 constantes de calcul, toutes éditables depuis l'interface.
class Menu::InvariantTest < MenuTestCase
  test "le menu couvre bien 112 journées" do
    assert_equal 16, Dish.distinct.count(:week_number)
    assert_equal 112, all_days.size
  end

  test "aucune journée ne passe sous un minimum" do
    minimums = target.macro_minimums
    failing = all_days.reject { |day| day.totals.meets?(minimums) }

    assert_empty failing.map { |d| "#{d.name} (#{d.totals.shortfalls(minimums).join(', ')})" },
                 "des journées n'atteignent pas la cible"
  end

  test "toutes les recettes sont résolues pour la cible active" do
    assert_equal Dish.count, ResolvedDish.where(nutrition_target: target).count
    assert_equal FixedMeal.count * Ingredient::SEASONS.size,
                 ResolvedFixedMeal.where(nutrition_target: target).count
  end

  test "chaque plat reste à moins de 10 g de sa cible sur chaque macro" do
    slot = target.slot_target("dish")
    drifting = ResolvedDish.where(nutrition_target: target).includes(:dish).filter_map do |r|
      worst = [ r.protein_deviation, r.lipid_deviation, r.carb_deviation ].map { |d| d.to_f.abs }.max
      "#{r.dish.key} (#{worst.round(1)} g)" if worst > 10.0
    end
    assert_empty drifting
    assert_in_delta 36.5, slot[:protein], 0.1
  end

  test "les protéines et lipides de chaque plat collent à moins de 4 g" do
    # Ce sont les deux macros contraignantes : les glucides peuvent déborder
    # à cause des légumes de la base, pas les protéines ni les lipides.
    # Le seuil est à 4 g et non 3 parce que deux plats d'été (taboulé, caponata)
    # dépassent de 3,1 à 3,6 g en lipides : ce sont des DÉPASSEMENTS sur un
    # minimum, sans conséquence sur l'invariant journalier.
    off = ResolvedDish.where(nutrition_target: target).includes(:dish).filter_map do |r|
      worst = [ r.protein_deviation, r.lipid_deviation ].map { |d| d.to_f.abs }.max
      "#{r.dish.key} (#{worst.round(1)} g)" if worst > 4.0
    end
    assert_empty off
  end

  test "aucun plat ne manque sa cible protéique ou lipidique" do
    # Sous la cible, la tolérance est bien plus stricte : c'est un minimum.
    under = ResolvedDish.where(nutrition_target: target).includes(:dish).filter_map do |r|
      worst = [ r.protein_deviation.to_f, r.lipid_deviation.to_f ].min
      "#{r.dish.key} (#{worst.round(1)} g)" if worst < -2.0
    end
    assert_empty under
  end

  test "le dépassement calorique reste sous 10 % du plancher" do
    average = all_days.sum { |d| d.totals.kcal } / all_days.size
    ratio = average / target.floor_kcal
    assert_operator ratio, :<, 1.10, "moyenne #{average.round} kcal pour un plancher de #{target.floor_kcal.round}"
    assert_operator ratio, :>, 1.0
  end

  test "le surplus calorique vient surtout des fibres" do
    days = all_days
    average_fiber = days.sum { |d| d.totals.fiber } / days.size
    average_kcal  = days.sum { |d| d.totals.kcal } / days.size
    surplus = average_kcal - target.floor_kcal
    fiber_share = (average_fiber - target.fiber.to_f) * 2

    assert_operator fiber_share / surplus, :>, 0.4,
                    "les fibres devraient expliquer l'essentiel du dépassement"
  end

  test "le recalcul est reproductible" do
    before = ResolvedDish.where(nutrition_target: target).order(:dish_id).pluck(:grams)
    report = Menu::Recalculator.new(target).call
    after = ResolvedDish.where(nutrition_target: target).order(:dish_id).pluck(:grams)

    assert report.ok?, "recalcul en échec : #{report.shortfalls.size} journée(s)"
    assert_equal before, after, "deux résolutions successives donnent des grammages différents"
    assert_equal Dish.count, report.dishes
  end

  test "chaque semaine attribue les trois rôles et les bonnes portions" do
    Dish.distinct.pluck(:week_number).sort.each do |number|
      week = Menu::Week.new(target, number)
      assert_equal %w[A B F], week.roles.keys.sort, "semaine #{number}"
      # Le rôle F revient au plat qui se conserve le moins bien.
      assert_equal 14, week.roles.sum { |role, _| week.portions.fetch(role) },
                   "semaine #{number} : 14 repas midi + soir attendus"
    end
  end

  # Un plat non congelable ne tient que jusqu'à J+4 : il doit donc occuper le
  # rôle F, seul rôle dont les jours s'arrêtent au jeudi. Les rôles A et B
  # atteignent le dimanche, soit J+7, et supposent un passage au congélateur.
  #
  # CORRIGÉ — semaine 12. L'été comptait 5 plats non congelables pour
  # 4 semaines : par principe des tiroirs, une semaine en portait forcément
  # deux, et le second débordait sur le week-end. La salade niçoise (E12C)
  # est en réalité un « plat d'assemblage » : tout se congèle sauf l'avocat,
  # ajouté frais à chaque service (`Dish::STORAGE_MODES`, `storage_mode:
  # "assemblage"`). Elle compte donc à nouveau comme congelable pour le
  # placement, et la liste des violations retombe à vide.
  #
  # Ce test verrouille l'existant : la liste ne doit pas s'allonger.
  KNOWN_STORAGE_VIOLATIONS = [].freeze

  test "un plat non congelable ne déborde pas sur le week-end" do
    violations = Dish.distinct.pluck(:week_number).sort.flat_map do |number|
      week = Menu::Week.new(target, number)
      week.roles.filter_map do |role, dish|
        next if role == "F" || dish.freezable?
        "semaine #{number} : #{dish.key} en rôle #{role}"
      end
    end

    assert_equal KNOWN_STORAGE_VIOLATIONS, violations,
                 "la liste des plats mal placés a changé"
  end

  # Un test vert ne prouve rien s'il ne sait pas virer au rouge. Celui-ci
  # vérifie que le filet détecte bien une cible que le menu ne peut pas tenir.
  test "une cible hors de portée est détectée, pas passée sous silence" do
    impossible = NutritionTarget.create!(
      kcal: 3800, protein: 240, lipid: 120, carb: 400, fiber: 40,
      protein_margin: 1.0171, lipid_margin: 1.0054, carb_margin: 1.0,
      meal_shares_attributes: target.meal_shares.map { |s|
        s.attributes.except("id", "nutrition_target_id", "created_at", "updated_at")
      })

    report = Menu::Recalculator.new(impossible).call

    assert_not report.ok?, "une cible à 240 g de protéines devrait faire échouer le contrôle"
    assert_operator report.shortfalls.size, :>, 0
    assert_equal Dish.count, report.dishes, "le recalcul doit tout de même produire des grammages"
  end

  test "abaisser une borne de grammage se voit sur l'invariant" do
    # Les bornes sont éditables depuis l'interface : c'est le principal moyen
    # de casser silencieusement le plan. On vérifie que ça ne passe pas inaperçu.
    tofu = Ingredient.find_by!(key: "tofu_ferme")
    tofu.update!(max_grams: 80)

    Menu::Recalculator.new(target).call
    minimums = target.macro_minimums
    failing = all_days.reject { |day| day.totals.meets?(minimums) }

    assert_operator failing.size, :>, 0,
                    "brider le tofu à 80 g devrait faire chuter des journées sous la cible"
  end
end
