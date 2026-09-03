class Ingredient < ApplicationRecord
  SEASONS = %w[hiver printemps ete automne].freeze

  has_many :dish_components, dependent: :destroy
  has_many :dishes, through: :dish_components
  has_many :fixed_meal_components, dependent: :destroy
  has_many :seasonal_fruits, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :name, :aisle, :form, presence: true
  validates :protein, :lipid, :carb, :fiber,
            numericality: { greater_than_or_equal_to: 0 }
  validate  :bounds_are_ordered

  scope :levers, -> { where.not(min_grams: nil) }

  # kcal pour 100 g, convention française (fibres à 2 kcal/g).
  def kcal
    4 * protein.to_f + 9 * lipid.to_f + 4 * carb.to_f + 2 * fiber.to_f
  end

  # Macros apportées par `grams` grammes de cet ingrédient.
  def macros_for(grams)
    f = grams.to_f / 100.0
    Nutrition::Macros.new(protein: protein.to_f * f, lipid: lipid.to_f * f,
                          carb: carb.to_f * f, fiber: fiber.to_f * f)
  end

  # Ce qu'on met dans la liste de courses (le seitan s'achète en gluten sec).
  def purchase_ingredient
    purchase_key.present? ? self.class.find_by(key: purchase_key) : self
  end

  def rounding_step
    %w[sec condiment].include?(form) ? 5 : 10
  end

  private

  def bounds_are_ordered
    return if min_grams.blank? || max_grams.blank?
    errors.add(:max_grams, "doit être supérieur à min_grams") if max_grams <= min_grams
  end
end
