class ActivityLevel < ApplicationRecord
  has_many :profiles, dependent: :nullify

  validates :key, presence: true, uniqueness: true
  validates :factor, numericality: { greater_than: 1, less_than: 3 }

  default_scope { order(:position) }
end
