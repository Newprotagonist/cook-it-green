class Dish < ApplicationRecord
  has_many :dish_components, -> { order(:position) }, dependent: :destroy
  has_many :ingredients, through: :dish_components
  has_many :resolved_dishes, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :name, :season, :letter, presence: true
  validates :week_number, numericality: { only_integer: true, greater_than: 0 }
  validate  :exactly_three_levers

  scope :for_week, ->(n) { where(week_number: n).order(:letter) }
  scope :for_season, ->(s) { where(season: s) }

  def base_components  = dish_components.select { |c| c.role == "base" }
  def lever_components = dish_components.select { |c| c.role == "lever" }

  def resolved_for(target)
    resolved_dishes.find_by(nutrition_target: target)
  end

  private

  # Le solveur travaille sur exactement trois leviers : un apport protéique,
  # un apport glucidique et une matière grasse. Moins, le système est sous-déterminé ;
  # plus, il devient sous-contraint et les solutions cessent d'être culinairement sensées.
  def exactly_three_levers
    return if dish_components.empty?
    count = dish_components.count { |c| c.role == "lever" }
    errors.add(:base, "doit avoir exactement 3 leviers (#{count} trouvés)") unless count == 3
  end
end
