# frozen_string_literal: true

#
# Charge db/seeds/menu_definitions.json : 127 ingrédients, 48 plats,
# 6 recettes fixes, la rotation hebdomadaire et les tables de référence
# du calcul des besoins. Idempotent — relançable sans doublon.

DEF = JSON.parse(File.read(Rails.root.join("db/seeds/menu_definitions.json")))
say = ->(msg) { puts "  #{msg}" }

# ---------------------------------------------------------------- ingrédients
DEF["ingredients"].each do |key, attrs|
  bounds = DEF["bornes"][key]
  purchase = DEF["achat"][key]
  Ingredient.find_or_initialize_by(key: key).update!(
    name: attrs["nom"],
    protein: attrs["P"], lipid: attrs["L"], carb: attrs["G"], fiber: attrs["F"],
    aisle: attrs["rayon"], form: attrs["forme"],
    min_grams: bounds&.first, max_grams: bounds&.last,
    purchase_key: purchase&.first, purchase_factor: purchase&.last || 1.0,
    canned_factor: DEF["conserve"][key],
    soak_time: DEF["trempage"][key], long_cook_time: DEF["cuisson_longue"][key]
  )
end
say.("#{Ingredient.count} ingrédients")

# ------------------------------------------------------------ fruits de saison
DEF["fruits_saison"].each do |season, keys|
  keys.each_with_index do |key, position|
    fruit = SeasonalFruit.find_or_initialize_by(season: season, position: position)
    fruit.update!(ingredient: Ingredient.find_by!(key: key))
  end
end
say.("#{SeasonalFruit.count} fruits de saison")

# ---------------------------------------------------------------------- plats
DEF["plats"].each do |row|
  overlap = row["base"].keys & row["leviers"]
  raise "#{row['id']} : #{overlap.inspect} à la fois en base et en levier" if overlap.any?

  fresh = row["montage_frais"] || []
  dish = Dish.find_or_initialize_by(key: row["id"])
  dish.assign_attributes(
    season: row["saison"], week_number: row["semaine"], letter: row["lettre"],
    name: row["nom"], summary: row["resume"], steps: row["etapes"],
    storage: row["conservation"],
    storage_mode: fresh.any? ? "assemblage" : (row["congelable"] ? "congelable" : "frais"),
    equipment: row["materiel"]
  )
  dish.save!(validate: false)
  dish.dish_components.destroy_all

  position = 0
  row["base"].each do |key, grams|
    dish.dish_components.create!(ingredient: Ingredient.find_by!(key: key), grams: grams,
                                role: "base", position: position += 1, assembled_fresh: fresh.include?(key))
  end
  row["leviers"].each do |key|
    dish.dish_components.create!(ingredient: Ingredient.find_by!(key: key),
                                role: "lever", position: position += 1, assembled_fresh: fresh.include?(key))
  end
  dish.reload.validate! # les 3 leviers, maintenant que les composants existent
end
say.("#{Dish.count} plats, #{DishComponent.count} composants")

# -------------------------------------------------- petits-déjeuners & collations
seed_fixed = lambda do |rows, kind|
  rows.each_with_index do |row, index|
    meal = FixedMeal.find_or_initialize_by(key: row["id"])
    meal.update!(kind: kind, position: index, name: row["nom"], summary: row["resume"],
                 steps: row["etapes"], powder_free_variant: row["variante_sans_poudre"])
    meal.fixed_meal_components.destroy_all

    position = 0
    row["base"].each do |key, grams|
      fruit = key == "@FRUIT"
      meal.fixed_meal_components.create!(
        ingredient: fruit ? nil : Ingredient.find_by!(key: key),
        grams: grams, role: "base", seasonal_fruit: fruit, position: position += 1)
    end
    row["leviers"].each do |key|
      fruit = key == "@FRUIT"
      meal.fixed_meal_components.create!(
        ingredient: fruit ? nil : Ingredient.find_by!(key: key),
        role: "lever", seasonal_fruit: fruit, position: position += 1)
    end
  end
end
seed_fixed.(DEF["petits_dejeuners"], "breakfast")
seed_fixed.(DEF["collations"], "snack")
say.("#{FixedMeal.count} recettes fixes, #{FixedMealComponent.count} composants")

# ------------------------------------------------------------------ paramètres
NutritionSetting.current.update!(
  fiber_per_1000_kcal: DEF["meta"]["fibres_par_1000kcal"],
  plant_protein_multiplier: DEF["meta"]["majoration_proteine_vegetale"],
  min_carb_g_per_kg: 0.8, min_lipid_kcal_share: 0.22,
  solver_step_dishes: 5, solver_step_fixed_meals: 2, undershoot_penalty: 40
)

DEF["activites"].each_with_index do |row, index|
  ActivityLevel.find_or_initialize_by(key: row["id"]).update!(
    name: row["nom"], factor: row["nap"], description: row["detail"], position: index)
end

# Recommandations OMNIVORES. La majoration végétale (x1,15) est appliquée une
# seule fois, dans Nutrition::NeedsCalculator. Le JSON exporté portait des
# valeurs déjà majorées, ce qui aboutissait à 2,53 g/kg en perte de gras :
# on repart donc des bases omnivores.
OMNIVORE_PROTEIN = { "perte" => 1.90, "recomp" => 1.75, "maintien" => 1.50, "prise" => 1.70 }.freeze

DEF["objectifs"].each_with_index do |row, index|
  Goal.find_or_initialize_by(key: row["id"]).update!(
    name: row["nom"], kcal_delta: row["delta"],
    protein_g_per_kg: OMNIVORE_PROTEIN.fetch(row["id"]),
    lipid_g_per_kg: row["lip"], description: row["detail"], position: index)
end
say.("#{ActivityLevel.count} niveaux d'activité, #{Goal.count} objectifs")

Profile.current.update!(sex: "male", age: 35, weight_kg: 70, height_cm: 178,
                        activity_level: ActivityLevel.find_by(key: "modere"),
                        goal: Goal.find_by(key: "perte"))

# ---------------------------------------------------------------------- cibles
FRACTIONS = DEF["meta"]["fractions"]
MARGIN    = DEF["meta"]["marge"]
SLOTS = [ [ "breakfast", "petit_dej", 1 ], [ "dish", "plat", 2 ], [ "snack", "collation", 1 ] ].freeze

# Cible unique (singleton, comme Profile) : seul le premier preset sert à l'initialiser.
preset = DEF["presets"].first
target = NutritionTarget.first_or_initialize
target.assign_attributes(
  kcal: preset["cible"]["kcal"], protein: preset["cible"]["P"],
  lipid: preset["cible"]["L"], carb: preset["cible"]["G"], fiber: preset["cible"]["F"],
  protein_margin: MARGIN["P"], lipid_margin: MARGIN["L"], carb_margin: MARGIN["G"]
)
target.save!(validate: false)
target.meal_shares.destroy_all
SLOTS.each_with_index do |(slot, source_key, servings), position|
  f = FRACTIONS[source_key]
  target.meal_shares.create!(slot: slot, servings_per_day: servings, position: position,
                             protein_share: f["P"], lipid_share: f["L"], carb_share: f["G"])
end
target.reload.validate!
say.("#{NutritionTarget.count} cible, #{MealShare.count} répartitions")

# ------------------------------------------------------------------- rotation
DEF["pattern"].each_with_index do |(lunch, dinner), day|
  WeekPattern.find_or_initialize_by(day_index: day).update!(
    lunch_role: lunch, dinner_role: dinner,
    breakfast_position: DEF["rot_pd"][day], snack_position: DEF["rot_col"][day],
    from_freezer: day >= 4, revival: DEF["relances"][day % DEF["relances"].size])
end

DEF["portions"].each do |role, count|
  description = role == "F" ? "Le plat qui se conserve le moins bien : consommé du lundi au jeudi." \
                            : "Réparti sur la semaine, portions de fin de semaine congelées."
  RolePortion.find_or_initialize_by(role: role).update!(portions: count, description: description)
end
say.("#{WeekPattern.count} jours de rotation, #{RolePortion.count} rôles")

puts "\nSeed terminé. Cible : #{NutritionTarget.current&.floor_kcal&.round} kcal"
