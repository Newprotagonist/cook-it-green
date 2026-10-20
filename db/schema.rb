# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_20_113459) do
  create_table "activity_levels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "factor", precision: 4, scale: 3, null: false
    t.string "key", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_activity_levels_on_key", unique: true
  end

  create_table "dish_components", force: :cascade do |t|
    t.boolean "assembled_fresh", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "dish_id", null: false
    t.decimal "grams", precision: 8, scale: 2
    t.integer "ingredient_id", null: false
    t.integer "position", default: 0, null: false
    t.string "role", default: "base", null: false
    t.datetime "updated_at", null: false
    t.index ["dish_id", "ingredient_id"], name: "index_dish_components_on_dish_id_and_ingredient_id", unique: true
    t.index ["dish_id"], name: "index_dish_components_on_dish_id"
    t.index ["ingredient_id"], name: "index_dish_components_on_ingredient_id"
  end

  create_table "dishes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "equipment"
    t.string "key", null: false
    t.string "letter", null: false
    t.string "name", null: false
    t.string "season", null: false
    t.json "steps", default: [], null: false
    t.string "storage"
    t.string "storage_mode", default: "frais", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.integer "week_number", null: false
    t.index ["key"], name: "index_dishes_on_key", unique: true
    t.index ["season", "week_number"], name: "index_dishes_on_season_and_week_number"
  end

  create_table "fixed_meal_components", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "fixed_meal_id", null: false
    t.decimal "grams", precision: 8, scale: 2
    t.integer "ingredient_id"
    t.integer "position", default: 0, null: false
    t.string "role", default: "base", null: false
    t.boolean "seasonal_fruit", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["fixed_meal_id"], name: "index_fixed_meal_components_on_fixed_meal_id"
    t.index ["ingredient_id"], name: "index_fixed_meal_components_on_ingredient_id"
  end

  create_table "fixed_meals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.text "powder_free_variant"
    t.json "steps", default: [], null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_fixed_meals_on_key", unique: true
    t.index ["kind", "position"], name: "index_fixed_meals_on_kind_and_position", unique: true
  end

  create_table "goals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "kcal_delta", precision: 5, scale: 3, default: "0.0", null: false
    t.string "key", null: false
    t.decimal "lipid_g_per_kg", precision: 5, scale: 2, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.decimal "protein_g_per_kg", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_goals_on_key", unique: true
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "aisle", null: false
    t.decimal "canned_factor", precision: 5, scale: 2
    t.decimal "carb", precision: 6, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.decimal "fiber", precision: 6, scale: 2, default: "0.0", null: false
    t.string "form", null: false
    t.string "key", null: false
    t.decimal "lipid", precision: 6, scale: 2, default: "0.0", null: false
    t.string "long_cook_time"
    t.integer "max_grams"
    t.integer "min_grams"
    t.string "name", null: false
    t.decimal "protein", precision: 6, scale: 2, default: "0.0", null: false
    t.decimal "purchase_factor", precision: 7, scale: 4, default: "1.0", null: false
    t.string "purchase_key"
    t.string "soak_time"
    t.datetime "updated_at", null: false
    t.index ["aisle"], name: "index_ingredients_on_aisle"
    t.index ["key"], name: "index_ingredients_on_key", unique: true
  end

  create_table "meal_shares", force: :cascade do |t|
    t.decimal "carb_share", precision: 7, scale: 6, null: false
    t.datetime "created_at", null: false
    t.decimal "lipid_share", precision: 7, scale: 6, null: false
    t.integer "nutrition_target_id", null: false
    t.integer "position", default: 0, null: false
    t.decimal "protein_share", precision: 7, scale: 6, null: false
    t.integer "servings_per_day", default: 1, null: false
    t.string "slot", null: false
    t.datetime "updated_at", null: false
    t.index ["nutrition_target_id", "slot"], name: "index_meal_shares_on_nutrition_target_id_and_slot", unique: true
    t.index ["nutrition_target_id"], name: "index_meal_shares_on_nutrition_target_id"
  end

  create_table "nutrition_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "fiber_per_1000_kcal", precision: 6, scale: 2, default: "14.0", null: false
    t.decimal "min_carb_g_per_kg", precision: 5, scale: 2, default: "0.8", null: false
    t.decimal "min_lipid_kcal_share", precision: 5, scale: 3, default: "0.22", null: false
    t.decimal "plant_protein_multiplier", precision: 5, scale: 3, default: "1.15", null: false
    t.integer "solver_step_dishes", default: 5, null: false
    t.integer "solver_step_fixed_meals", default: 2, null: false
    t.integer "undershoot_penalty", default: 40, null: false
    t.datetime "updated_at", null: false
  end

  create_table "nutrition_targets", force: :cascade do |t|
    t.decimal "carb", precision: 6, scale: 1, null: false
    t.decimal "carb_margin", precision: 6, scale: 4, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.decimal "fiber", precision: 6, scale: 1, null: false
    t.integer "kcal", null: false
    t.decimal "lipid", precision: 6, scale: 1, null: false
    t.decimal "lipid_margin", precision: 6, scale: 4, default: "1.0054", null: false
    t.decimal "protein", precision: 6, scale: 1, null: false
    t.decimal "protein_margin", precision: 6, scale: 4, default: "1.0171", null: false
    t.datetime "resolved_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_nutrition_targets_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.integer "activity_level_id"
    t.integer "age"
    t.decimal "body_fat_pct", precision: 4, scale: 1
    t.datetime "created_at", null: false
    t.integer "goal_id"
    t.decimal "height_cm", precision: 5, scale: 1
    t.string "sex", default: "male", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.decimal "weight_kg", precision: 5, scale: 1
    t.index ["activity_level_id"], name: "index_profiles_on_activity_level_id"
    t.index ["goal_id"], name: "index_profiles_on_goal_id"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth_key", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.string "p256dh_key", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id", "endpoint"], name: "index_push_subscriptions_on_user_id_and_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "resolved_dishes", force: :cascade do |t|
    t.decimal "carb", precision: 7, scale: 2
    t.decimal "carb_deviation", precision: 7, scale: 2
    t.datetime "created_at", null: false
    t.integer "dish_id", null: false
    t.decimal "fiber", precision: 7, scale: 2
    t.json "grams", default: {}, null: false
    t.decimal "kcal", precision: 8, scale: 2
    t.decimal "lipid", precision: 7, scale: 2
    t.decimal "lipid_deviation", precision: 7, scale: 2
    t.integer "nutrition_target_id", null: false
    t.decimal "protein", precision: 7, scale: 2
    t.decimal "protein_deviation", precision: 7, scale: 2
    t.datetime "updated_at", null: false
    t.index ["dish_id"], name: "index_resolved_dishes_on_dish_id"
    t.index ["nutrition_target_id", "dish_id"], name: "index_resolved_dishes_on_target_and_dish", unique: true
    t.index ["nutrition_target_id"], name: "index_resolved_dishes_on_nutrition_target_id"
  end

  create_table "resolved_fixed_meals", force: :cascade do |t|
    t.decimal "carb", precision: 7, scale: 2
    t.decimal "carb_deviation", precision: 7, scale: 2
    t.datetime "created_at", null: false
    t.decimal "fiber", precision: 7, scale: 2
    t.integer "fixed_meal_id", null: false
    t.json "grams", default: {}, null: false
    t.decimal "kcal", precision: 8, scale: 2
    t.decimal "lipid", precision: 7, scale: 2
    t.decimal "lipid_deviation", precision: 7, scale: 2
    t.integer "nutrition_target_id", null: false
    t.decimal "protein", precision: 7, scale: 2
    t.decimal "protein_deviation", precision: 7, scale: 2
    t.string "season", null: false
    t.datetime "updated_at", null: false
    t.index ["fixed_meal_id"], name: "index_resolved_fixed_meals_on_fixed_meal_id"
    t.index ["nutrition_target_id", "fixed_meal_id", "season"], name: "index_resolved_fixed_meals_on_target_meal_season", unique: true
    t.index ["nutrition_target_id"], name: "index_resolved_fixed_meals_on_nutrition_target_id"
  end

  create_table "role_portions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "portions", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["role"], name: "index_role_portions_on_role", unique: true
  end

  create_table "seasonal_fruits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "ingredient_id", null: false
    t.integer "position", null: false
    t.string "season", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_seasonal_fruits_on_ingredient_id"
    t.index ["season", "position"], name: "index_seasonal_fruits_on_season_and_position", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "demo", default: false, null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "week_patterns", force: :cascade do |t|
    t.integer "breakfast_position", null: false
    t.datetime "created_at", null: false
    t.integer "day_index", null: false
    t.string "dinner_role", null: false
    t.boolean "from_freezer", default: false, null: false
    t.string "lunch_role", null: false
    t.text "revival"
    t.integer "snack_position", null: false
    t.datetime "updated_at", null: false
    t.index ["day_index"], name: "index_week_patterns_on_day_index", unique: true
  end

  add_foreign_key "dish_components", "dishes"
  add_foreign_key "dish_components", "ingredients"
  add_foreign_key "fixed_meal_components", "fixed_meals"
  add_foreign_key "fixed_meal_components", "ingredients"
  add_foreign_key "meal_shares", "nutrition_targets"
  add_foreign_key "nutrition_targets", "users"
  add_foreign_key "profiles", "activity_levels"
  add_foreign_key "profiles", "goals"
  add_foreign_key "profiles", "users"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "resolved_dishes", "dishes"
  add_foreign_key "resolved_dishes", "nutrition_targets"
  add_foreign_key "resolved_fixed_meals", "fixed_meals"
  add_foreign_key "resolved_fixed_meals", "nutrition_targets"
  add_foreign_key "seasonal_fruits", "ingredients"
  add_foreign_key "sessions", "users"
end
