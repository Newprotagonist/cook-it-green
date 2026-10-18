class AddUserRefToNutritionTargets < ActiveRecord::Migration[8.1]
  def change
    add_reference :nutrition_targets, :user, null: true, foreign_key: true
  end
end
