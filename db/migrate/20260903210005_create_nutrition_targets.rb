class CreateNutritionTargets < ActiveRecord::Migration[8.1]
  def change
    create_table :nutrition_targets do |t|
      t.string  :name, null: false
      t.boolean :active, null: false, default: false
      # Les quatre minimums quotidiens. kcal est informatif : il découle des macros.
      t.integer :kcal, null: false
      t.decimal :protein, precision: 6, scale: 1, null: false
      t.decimal :lipid,   precision: 6, scale: 1, null: false
      t.decimal :carb,    precision: 6, scale: 1, null: false
      t.decimal :fiber,   precision: 6, scale: 1, null: false
      # Marges d'arrondi : on vise légèrement au-dessus du minimum pour absorber
      # le pas de 5 g du solveur.
      t.decimal :protein_margin, precision: 6, scale: 4, null: false, default: 1.0171
      t.decimal :lipid_margin,   precision: 6, scale: 4, null: false, default: 1.0054
      t.decimal :carb_margin,    precision: 6, scale: 4, null: false, default: 1.0
      t.string  :source, null: false, default: "manual"   # manual | computed | preset
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :nutrition_targets, :active

    # Répartition sur la journée. `dish` compte pour 2 prises (midi et soir visent
    # la même cible : c'est ce qui rend les plats interchangeables).
    create_table :meal_shares do |t|
      t.references :nutrition_target, null: false, foreign_key: true
      t.string  :slot, null: false            # breakfast | dish | snack
      t.integer :servings_per_day, null: false, default: 1
      t.decimal :protein_share, precision: 7, scale: 6, null: false
      t.decimal :lipid_share,   precision: 7, scale: 6, null: false
      t.decimal :carb_share,    precision: 7, scale: 6, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :meal_shares, [ :nutrition_target_id, :slot ], unique: true
  end
end
