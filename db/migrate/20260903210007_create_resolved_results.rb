class CreateResolvedResults < ActiveRecord::Migration[8.1]
  def change
    # Résultats du solveur, persistés par cible. Le solveur coûte ~1 s en Ruby :
    # on le lance à chaque changement de cible, pas à chaque requête.
    create_table :resolved_dishes do |t|
      t.references :nutrition_target, null: false, foreign_key: true
      t.references :dish, null: false, foreign_key: true
      t.json    :grams, null: false, default: {}
      t.decimal :kcal,    precision: 8, scale: 2
      t.decimal :protein, precision: 7, scale: 2
      t.decimal :lipid,   precision: 7, scale: 2
      t.decimal :carb,    precision: 7, scale: 2
      t.decimal :fiber,   precision: 7, scale: 2
      t.decimal :protein_deviation, precision: 7, scale: 2
      t.decimal :lipid_deviation,   precision: 7, scale: 2
      t.decimal :carb_deviation,    precision: 7, scale: 2
      t.timestamps
    end
    add_index :resolved_dishes, [ :nutrition_target_id, :dish_id ],
              unique: true, name: "index_resolved_dishes_on_target_and_dish"

    create_table :resolved_fixed_meals do |t|
      t.references :nutrition_target, null: false, foreign_key: true
      t.references :fixed_meal, null: false, foreign_key: true
      t.string  :season, null: false
      t.json    :grams, null: false, default: {}
      t.decimal :kcal,    precision: 8, scale: 2
      t.decimal :protein, precision: 7, scale: 2
      t.decimal :lipid,   precision: 7, scale: 2
      t.decimal :carb,    precision: 7, scale: 2
      t.decimal :fiber,   precision: 7, scale: 2
      t.decimal :protein_deviation, precision: 7, scale: 2
      t.decimal :lipid_deviation,   precision: 7, scale: 2
      t.decimal :carb_deviation,    precision: 7, scale: 2
      t.timestamps
    end
    add_index :resolved_fixed_meals, [ :nutrition_target_id, :fixed_meal_id, :season ],
              unique: true, name: "index_resolved_fixed_meals_on_target_meal_season"
  end
end
