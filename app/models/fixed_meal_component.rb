class FixedMealComponent < ApplicationRecord
  ROLES = %w[base lever].freeze

  belongs_to :fixed_meal
  belongs_to :ingredient, optional: true

  validates :role, inclusion: { in: ROLES }
  validates :ingredient, presence: true, unless: :seasonal_fruit?

  # Résout l'emplacement « fruit de saison » pour une saison donnée.
  def ingredient_for(season)
    return ingredient unless seasonal_fruit?
    SeasonalFruit.find_by(season: season, position: fixed_meal.position)&.ingredient
  end
end
