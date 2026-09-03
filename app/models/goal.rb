class Goal < ApplicationRecord
  has_many :profiles, dependent: :nullify

  validates :key, presence: true, uniqueness: true
  # protein_g_per_kg est la recommandation OMNIVORE. La majoration végétale
  # (NutritionSetting#plant_protein_multiplier) s'applique une seule fois,
  # dans Nutrition::NeedsCalculator.
  validates :protein_g_per_kg, numericality: { greater_than: 0.5, less_than: 3.0 }
  validates :lipid_g_per_kg,   numericality: { greater_than: 0.3 }

  default_scope { order(:position) }
end
