require "test_helper"

class DishTest < SeededTestCase
  test "storage_mode n'accepte que les trois états connus" do
    dish = Dish.first.dup
    dish.storage_mode = "sous_vide"
    assert_not dish.valid?
    assert dish.errors[:storage_mode].any?
  end

  test "freezable? est vrai pour congelable et assemblage, faux pour frais" do
    assert Dish.new(storage_mode: "congelable").freezable?
    assert Dish.new(storage_mode: "assemblage").freezable?
    assert_not Dish.new(storage_mode: "frais").freezable?
  end

  test "un plat d'assemblage sans composant frais est invalide" do
    dish = Dish.for_season("ete").find_by!(letter: "A")
    dish.storage_mode = "assemblage"
    assert_not dish.valid?
    assert_match(/assemblage sans composant frais/, dish.errors.full_messages.join)
  end

  test "la salade niçoise (E12C) est un plat d'assemblage, l'avocat en composant frais" do
    dish = Dish.find_by!(key: "E12C")
    assert_equal "assemblage", dish.storage_mode
    assert dish.assembly?
    assert dish.freezable?

    fresh = dish.fresh_components
    assert_equal [ "avocat" ], fresh.map { |c| c.ingredient.key }
  end
end
