class SimplifyNutritionTargetToSingleton < ActiveRecord::Migration[8.1]
  def up
    # Garde uniquement la cible active (ou la plus récente à défaut) ; les autres ne sont
    # jamais appliquées au menu. Passe par le modèle (pas du SQL brut) pour que
    # dependent: :destroy nettoie meal_shares/resolved_dishes/resolved_fixed_meals au
    # passage — une suppression SQL directe se heurte aux contraintes de clé étrangère.
    keeper = NutritionTarget.where(active: true).order(created_at: :desc).first ||
             NutritionTarget.order(created_at: :desc).first
    NutritionTarget.where.not(id: keeper.id).destroy_all if keeper

    remove_index :nutrition_targets, :active
    remove_column :nutrition_targets, :active
    remove_column :nutrition_targets, :name
    remove_column :nutrition_targets, :source
  end

  def down
    add_column :nutrition_targets, :source, :string, default: "manual", null: false
    add_column :nutrition_targets, :name, :string
    add_column :nutrition_targets, :active, :boolean, default: true, null: false
    add_index :nutrition_targets, :active
  end
end
