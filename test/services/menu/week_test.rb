require "test_helper"

class Menu::WeekTest < MenuTestCase
  def week_using(ingredient_key)
    ingredient = Ingredient.find_by!(key: ingredient_key)
    number = Dish.joins(:dish_components)
                 .where(dish_components: { ingredient_id: ingredient.id })
                 .first.week_number
    Menu::Week.new(target, number)
  end

  def lines_of(week) = week.shopping_list.values.flatten

  test "le seitan s'achète en gluten sec, jamais tel quel" do
    week = week_using("seitan")
    lines = lines_of(week)

    assert_nil lines.find { |l| l.ingredient.key == "seitan" },
               "le seitan cuit ne s'achète pas : il se fabrique"
    gluten = lines.find { |l| l.ingredient.key == "gluten_sec" }
    assert gluten, "le gluten de blé devrait figurer sur la liste"

    cooked = week.roles.sum do |role, dish|
      resolved = ResolvedDish.find_by(nutrition_target: target, dish: dish)
      (resolved.grams["seitan"] || 0).to_f * week.portions.fetch(role)
    end
    expected = cooked / 3.0

    assert_operator gluten.grams, :>=, expected
    assert_operator gluten.grams - expected, :<, 5, "arrondi trop généreux"
    assert_equal 0, gluten.grams % 5, "les produits secs s'arrondissent au multiple de 5 g"
  end

  test "les légumineuses sèches portent leur équivalent en conserve" do
    week = week_using("lentilles_corail")
    line = lines_of(week).find { |l| l.ingredient.key == "lentilles_corail" }

    assert line
    assert_match(/égouttés en conserve/, line.note.to_s)
    assert_match(/\d+ g/, line.note.to_s)
  end

  test "les arrondis suivent la forme du produit" do
    week = Menu::Week.new(target, Dish.first.week_number)
    lines_of(week).each do |line|
      step = %w[sec condiment].include?(line.ingredient.form) ? 5 : 10
      assert_equal 0, line.grams % step,
                   "#{line.ingredient.name} (#{line.ingredient.form}) : #{line.grams} g"
    end
  end

  test "la liste inclut les petits-déjeuners et collations, pas seulement les plats" do
    week = Menu::Week.new(target, Dish.first.week_number)
    keys = lines_of(week).map { |l| l.ingredient.key }
    breakfast_only = ResolvedFixedMeal.where(nutrition_target: target, season: week.season)
                                      .flat_map { |r| r.grams.keys }.uniq
    assert (breakfast_only & keys).any?,
           "aucun ingrédient de petit-déjeuner ou de collation dans la liste de courses"
  end

  test "la session de batch annonce les trempages avant le jour J" do
    week = week_using("pois_chiches")
    veille = week.batch_plan.first
    assert_equal "La veille", veille.time
    assert_match(/tremper/i, veille.actions.join(" "))
  end

  test "la session tient en sept étapes au plus, dont la pesée finale" do
    week = Menu::Week.new(target, Dish.first.week_number)
    plan = week.batch_plan
    assert_operator plan.size, :<=, 7
    assert_match(/pesée|étiquetage/i, plan.last.title)
    assert_match(/#{week.portions['F']} portions/, plan.last.actions.join(" "))
  end

  test "les trois derniers jours sortent du congélateur" do
    week = Menu::Week.new(target, Dish.first.week_number)
    assert_equal 3, week.days.count(&:from_freezer)
    assert_equal %w[Vendredi Samedi Dimanche], week.days.select(&:from_freezer).map(&:name)
  end

  test "un plat d'assemblage se congèle sauf son composant frais" do
    dish = Dish.find_by!(key: "E12C")
    week = Menu::Week.new(target, dish.week_number)

    assert dish.assembly?
    assert dish.freezable?, "un plat d'assemblage compte comme congelable pour le placement"
    assert_not_equal "F", week.roles.key(dish), "il n'a plus besoin du rôle F"
    assert_match(/réserver avocat/i, week.batch_plan.last.actions.join(" "))
  end

  test "jamais deux fois le même plat dans une journée" do
    Dish.distinct.pluck(:week_number).each do |number|
      Menu::Week.new(target, number).days.each do |day|
        assert_not_equal day.lunch_role, day.dinner_role, "semaine #{number}, #{day.name}"
      end
    end
  end
end
