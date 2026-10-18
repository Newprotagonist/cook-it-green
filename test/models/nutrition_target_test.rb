require "test_helper"

class NutritionTargetTest < SeededTestCase
  test "le plancher calorique suit la convention française" do
    t = NutritionTarget.new(protein: 117, lipid: 93, carb: 130, fiber: 19)
    assert_in_delta 1863.0, t.floor_kcal, 0.01
  end

  test "refuse une répartition dont la somme n'est pas 1" do
    t = target.dup
    t.meal_shares.build(slot: "breakfast", servings_per_day: 1,
                        protein_share: 0.5, lipid_share: 0.5, carb_share: 0.5)
    assert_not t.valid?
    assert_match(/somme/, t.errors[:meal_shares].join)
  end

  test "la répartition de la cible active somme bien à 1 pour chaque macro" do
    %i[protein_share lipid_share carb_share].each do |attr|
      total = target.meal_shares.sum { |s| s.public_send(attr).to_f * s.servings_per_day }
      assert_in_delta 1.0, total, 0.005, attr.to_s
    end
  end

  test "le plat compte pour deux prises par jour" do
    assert_equal 2, target.meal_shares.find { |s| s.slot == "dish" }.servings_per_day
  end

  test "la cible d'une prise applique part et marge" do
    share = target.meal_shares.find { |s| s.slot == "dish" }
    expected = target.protein.to_f * target.protein_margin.to_f * share.protein_share.to_f
    assert_in_delta expected, target.slot_target("dish")[:protein], 0.001
  end
end
