require "test_helper"

class Nutrition::MacrosTest < ActiveSupport::TestCase
  test "convention française : fibres à 2 kcal/g, glucides hors fibres" do
    m = Nutrition::Macros.new(protein: 117.0, lipid: 93.0, carb: 130.0, fiber: 19.0)
    # C'est l'identité qui rendait la cible initiale auto-cohérente.
    assert_in_delta 1863.0, m.kcal, 0.01
  end

  test "les kcal hors fibres retirent bien 2 kcal par gramme" do
    m = Nutrition::Macros.new(protein: 10.0, lipid: 10.0, carb: 10.0, fiber: 20.0)
    assert_in_delta m.kcal - 40.0, m.kcal_excluding_fiber, 0.01
  end

  test "meets? tolère un dixième de gramme mais pas davantage" do
    m = Nutrition::Macros.new(protein: 116.99, lipid: 93.0, carb: 130.0, fiber: 19.0)
    assert m.meets?(protein: 117.0, lipid: 93.0, carb: 130.0, fiber: 19.0)

    short = Nutrition::Macros.new(protein: 116.0, lipid: 93.0, carb: 130.0, fiber: 19.0)
    assert_not short.meets?(protein: 117.0, lipid: 93.0, carb: 130.0, fiber: 19.0)
    assert_equal [ :protein ], short.shortfalls(protein: 117.0, lipid: 93.0, carb: 130.0, fiber: 19.0)
  end

  test "l'addition cumule chaque macronutriment" do
    a = Nutrition::Macros.new(protein: 1.0, lipid: 2.0, carb: 3.0, fiber: 4.0)
    sum = a + a
    assert_equal [ 2.0, 4.0, 6.0, 8.0 ], [ sum.protein, sum.lipid, sum.carb, sum.fiber ]
  end
end
