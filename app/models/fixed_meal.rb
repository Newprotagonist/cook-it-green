# Petits-déjeuners et collations : structure identique toute l'année,
# seul le fruit de saison change.
class FixedMeal < ApplicationRecord
  KINDS = %w[breakfast snack].freeze

  has_many :fixed_meal_components, -> { order(:position) }, dependent: :destroy
  has_many :resolved_fixed_meals, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }
  validates :name, presence: true

  scope :breakfasts, -> { where(kind: "breakfast").order(:position) }
  scope :snacks,     -> { where(kind: "snack").order(:position) }

  def slot = kind == "breakfast" ? "breakfast" : "snack"

  def resolved_for(target, season)
    resolved_fixed_meals.find_by(nutrition_target: target, season: season)
  end
end
