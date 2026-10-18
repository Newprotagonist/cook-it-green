class Profile < ApplicationRecord
  SEXES = %w[male female].freeze

  belongs_to :user
  belongs_to :activity_level, optional: true
  belongs_to :goal, optional: true

  validates :sex, inclusion: { in: SEXES }
  validates :age,       numericality: { in: 14..99 }, allow_nil: true
  validates :weight_kg, numericality: { in: 35..250 }, allow_nil: true
  validates :height_cm, numericality: { in: 130..230 }, allow_nil: true
  validates :body_fat_pct, numericality: { in: 3..60 }, allow_nil: true

  def needs = Nutrition::NeedsCalculator.new(self)

  def complete? = age.present? && weight_kg.present? && height_cm.present?
end
