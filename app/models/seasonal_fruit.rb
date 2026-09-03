class SeasonalFruit < ApplicationRecord
  belongs_to :ingredient

  validates :season, inclusion: { in: Ingredient::SEASONS }
  validates :position, uniqueness: { scope: :season }
end
