class DishComponent < ApplicationRecord
  ROLES = %w[base lever].freeze

  belongs_to :dish
  belongs_to :ingredient

  validates :role, inclusion: { in: ROLES }
  validates :grams, presence: true, numericality: { greater_than: 0 }, if: -> { role == "base" }
  validates :grams, absence: true, if: -> { role == "lever" }

  scope :base,   -> { where(role: "base") }
  scope :levers, -> { where(role: "lever") }
end
