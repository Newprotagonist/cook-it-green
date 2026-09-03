class CreateNutritionReferenceTables < ActiveRecord::Migration[8.1]
  def change
    # Singleton : les constantes du calcul des besoins, éditables sans redéploiement.
    create_table :nutrition_settings do |t|
      t.decimal :fiber_per_1000_kcal,      precision: 6, scale: 2, null: false, default: 14.0
      t.decimal :plant_protein_multiplier, precision: 5, scale: 3, null: false, default: 1.15
      t.decimal :min_carb_g_per_kg,        precision: 5, scale: 2, null: false, default: 0.8
      t.decimal :min_lipid_kcal_share,     precision: 5, scale: 3, null: false, default: 0.22
      t.integer :solver_step_dishes,       null: false, default: 5
      t.integer :solver_step_fixed_meals,  null: false, default: 2
      t.integer :undershoot_penalty,       null: false, default: 40
      t.timestamps
    end

    create_table :activity_levels do |t|
      t.string  :key,  null: false
      t.string  :name, null: false
      t.decimal :factor, precision: 4, scale: 3, null: false
      t.text    :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :activity_levels, :key, unique: true

    create_table :goals do |t|
      t.string  :key,  null: false
      t.string  :name, null: false
      t.decimal :kcal_delta, precision: 5, scale: 3, null: false, default: 0
      # Base OMNIVORE : la majoration végétale de nutrition_settings s'applique par-dessus.
      # Les stocker déjà majorées reviendrait à compter la majoration deux fois.
      t.decimal :protein_g_per_kg, precision: 5, scale: 2, null: false
      t.decimal :lipid_g_per_kg,   precision: 5, scale: 2, null: false
      t.text    :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :goals, :key, unique: true

    create_table :profiles do |t|
      t.string  :sex, null: false, default: "male"
      t.integer :age
      t.decimal :weight_kg,    precision: 5, scale: 1
      t.decimal :height_cm,    precision: 5, scale: 1
      t.decimal :body_fat_pct, precision: 4, scale: 1
      t.references :activity_level, foreign_key: true
      t.references :goal,           foreign_key: true
      t.timestamps
    end
  end
end
