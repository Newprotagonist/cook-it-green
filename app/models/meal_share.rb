class MealShare < ApplicationRecord
  SLOTS = %w[breakfast dish snack].freeze

  belongs_to :nutrition_target

  validates :slot, inclusion: { in: SLOTS }, uniqueness: { scope: :nutrition_target_id }
  validates :servings_per_day, numericality: { only_integer: true, greater_than: 0 }
  validates :protein_share, :lipid_share, :carb_share,
            numericality: { greater_than: 0, less_than_or_equal_to: 1 }

  def label
    { "breakfast" => "Petit-déjeuner", "dish" => "Plat (midi et soir)", "snack" => "Collation" }[slot]
  end
end
