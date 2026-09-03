class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients do |t|
      t.string  :key,  null: false
      t.string  :name, null: false
      # Valeurs pour 100 g. Convention française : carb = glucides NETS, hors fibres.
      t.decimal :protein, precision: 6, scale: 2, null: false, default: 0
      t.decimal :lipid,   precision: 6, scale: 2, null: false, default: 0
      t.decimal :carb,    precision: 6, scale: 2, null: false, default: 0
      t.decimal :fiber,   precision: 6, scale: 2, null: false, default: 0
      t.string  :aisle, null: false
      t.string  :form,  null: false
      # Bornes du solveur quand l'ingrédient sert de levier. Les rendre éditables
      # permet d'élargir la plage calorique couverte sans toucher au code.
      t.integer :min_grams
      t.integer :max_grams
      # Ce qu'on achète réellement : 100 g de seitan cuit = 33 g de gluten sec.
      t.string  :purchase_key
      t.decimal :purchase_factor, precision: 7, scale: 4, null: false, default: 1.0
      t.decimal :canned_factor,   precision: 5, scale: 2
      t.string  :soak_time
      t.string  :long_cook_time
      t.timestamps
    end
    add_index :ingredients, :key, unique: true
    add_index :ingredients, :aisle
  end
end
