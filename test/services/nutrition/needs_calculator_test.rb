require "test_helper"

class Nutrition::NeedsCalculatorTest < SeededTestCase
  setup do
    @profile = owner.profile
    @profile.update!(sex: "male", age: 35, weight_kg: 70, height_cm: 178, body_fat_pct: nil,
                     activity_level: ActivityLevel.find_by!(key: "modere"),
                     goal: Goal.find_by!(key: "perte"))
  end

  test "Mifflin-St Jeor, constante masculine" do
    # 10*70 + 6,25*178 - 5*35 + 5
    assert_in_delta 1642.5, @profile.needs.basal_metabolic_rate, 0.01
    assert_equal "Mifflin-St Jeor", @profile.needs.method_name
  end

  test "Mifflin-St Jeor, constante féminine" do
    @profile.update!(sex: "female")
    assert_in_delta 1476.5, @profile.needs.basal_metabolic_rate, 0.01
  end

  test "bascule sur Katch-McArdle dès que la masse grasse est renseignée" do
    @profile.update!(body_fat_pct: 20)
    # 370 + 21,6 * (70 * 0,8)
    assert_equal "Katch-McArdle", @profile.needs.method_name
    assert_in_delta 1579.6, @profile.needs.basal_metabolic_rate, 0.01
  end

  test "un taux de masse grasse aberrant ne déclenche pas Katch-McArdle" do
    @profile.update!(body_fat_pct: 3)
    assert_equal "Mifflin-St Jeor", @profile.needs.method_name
  end

  # ------------------------------------------------------------------ RÉGRESSION
  test "la majoration protéique végétale ne s'applique qu'une seule fois" do
    multiplier = NutritionSetting.current.plant_protein_multiplier.to_f
    Goal.find_each do |goal|
      @profile.update!(goal: goal)
      expected = goal.protein_g_per_kg.to_f * multiplier
      assert_in_delta expected, @profile.needs.protein_g_per_kg, 0.001,
                      "#{goal.name} : la majoration est comptée deux fois"
    end
  end

  test "les objectifs stockent une base omnivore, pas une valeur déjà majorée" do
    # Le bug d'origine : le JSON portait des valeurs déjà végétales (2,2 g/kg),
    # que la majoration x1,15 poussait à 2,53 g/kg — hors de tout sens physiologique.
    Goal.find_each do |goal|
      assert_operator goal.protein_g_per_kg.to_f, :<=, 2.0,
                      "#{goal.name} : #{goal.protein_g_per_kg} g/kg semble déjà majoré"
    end
  end

  test "aucun objectif ne produit une cible protéique supérieure à 2,3 g/kg" do
    Goal.find_each do |goal|
      @profile.update!(goal: goal)
      assert_operator @profile.needs.protein_g_per_kg, :<=, 2.3, goal.name
    end
  end

  # ------------------------------------------------------------------- cohérence
  test "les macros déduites retombent sur l'objectif énergétique" do
    Goal.find_each do |goal|
      [ [ "male", 70, 178, 35 ], [ "female", 62, 168, 34 ], [ "male", 85, 183, 28 ] ].each do |sex, kg, cm, age|
        @profile.update!(sex: sex, weight_kg: kg, height_cm: cm, age: age, goal: goal)
        n = @profile.needs
        floor = 4 * n.protein + 9 * n.lipid_adjusted + 4 * n.carb + 2 * n.fiber
        assert_in_delta n.kcal, floor, 12,
                        "#{goal.key} #{sex} #{kg}kg : plancher #{floor} vs objectif #{n.kcal}"
      end
    end
  end

  test "les glucides ne passent jamais sous le plancher physiologique" do
    Goal.find_each do |goal|
      @profile.update!(goal: goal)
      n = @profile.needs
      assert_operator n.carb, :>=, n.carb_floor.floor, "#{goal.key} : glucides effondrés"
    end
  end

  test "usable? exige un profil complet" do
    assert @profile.needs.usable?
    @profile.update!(weight_kg: nil)
    assert_not @profile.needs.usable?
  end
end
