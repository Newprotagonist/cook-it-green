class CreateDishes < ActiveRecord::Migration[8.1]
  def change
    create_table :dishes do |t|
      t.string  :key,    null: false
      t.string  :season, null: false
      t.integer :week_number, null: false
      t.string  :letter, null: false
      t.string  :name,   null: false
      t.text    :summary
      t.json    :steps,  null: false, default: []
      t.string  :storage
      t.boolean :freezable, null: false, default: true
      t.string  :equipment
      t.timestamps
    end
    add_index :dishes, :key, unique: true
    add_index :dishes, [ :season, :week_number ]

    create_table :dish_components do |t|
      t.references :dish,       null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      # grams est NULL pour un levier : c'est le solveur qui le détermine.
      t.decimal :grams, precision: 8, scale: 2
      t.string  :role, null: false, default: "base"
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :dish_components, [ :dish_id, :ingredient_id ], unique: true
  end
end
