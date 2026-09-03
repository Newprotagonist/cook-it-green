class CreateFixedMeals < ActiveRecord::Migration[8.1]
  def change
    create_table :fixed_meals do |t|
      t.string  :key,  null: false
      t.string  :kind, null: false          # breakfast | snack
      t.integer :position, null: false
      t.string  :name, null: false
      t.text    :summary
      t.json    :steps, null: false, default: []
      t.text    :powder_free_variant
      t.timestamps
    end
    add_index :fixed_meals, :key, unique: true
    add_index :fixed_meals, [ :kind, :position ], unique: true

    create_table :fixed_meal_components do |t|
      t.references :fixed_meal, null: false, foreign_key: true
      # ingredient_id est NULL quand le composant est l'emplacement « fruit de saison ».
      t.references :ingredient, foreign_key: true
      t.decimal :grams, precision: 8, scale: 2
      t.string  :role, null: false, default: "base"
      t.boolean :seasonal_fruit, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :seasonal_fruits do |t|
      t.string  :season, null: false
      t.integer :position, null: false
      t.references :ingredient, null: false, foreign_key: true
      t.timestamps
    end
    add_index :seasonal_fruits, [ :season, :position ], unique: true
  end
end
