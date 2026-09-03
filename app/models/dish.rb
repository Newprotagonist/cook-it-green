class Dish < ApplicationRecord
  # « assemblage » : le plat se congèle comme les autres, à l'exception d'un
  # composant (`dish_components.assembled_fresh`) ajouté au dernier moment,
  # au service — cas de l'avocat dans la salade niçoise (E12C). Pour le
  # placement dans la semaine, il compte comme congelable : seul le composant
  # frais est concerné, pas le plat entier.
  STORAGE_MODES = %w[congelable frais assemblage].freeze
  FREEZER_COMPATIBLE_MODES = %w[congelable assemblage].freeze

  has_many :dish_components, -> { order(:position) }, dependent: :destroy
  has_many :ingredients, through: :dish_components
  has_many :resolved_dishes, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :name, :season, :letter, presence: true
  validates :week_number, numericality: { only_integer: true, greater_than: 0 }
  validates :storage_mode, inclusion: { in: STORAGE_MODES }
  validate  :exactly_three_levers
  validate  :assembly_needs_a_fresh_component

  scope :for_week, ->(n) { where(week_number: n).order(:letter) }
  scope :for_season, ->(s) { where(season: s) }

  def base_components  = dish_components.select { |c| c.role == "base" }
  def lever_components = dish_components.select { |c| c.role == "lever" }
  def fresh_components  = dish_components.select(&:assembled_fresh?)

  def freezable? = FREEZER_COMPATIBLE_MODES.include?(storage_mode)
  def assembly?  = storage_mode == "assemblage"

  def storage_label
    case storage_mode
    when "congelable" then "Se congèle"
    when "assemblage"  then "Se congèle, montage à la minute"
    else "Ne pas congeler"
    end
  end

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

  def assembly_needs_a_fresh_component
    return if dish_components.empty? || !assembly?
    errors.add(:base, "plat d'assemblage sans composant frais") unless dish_components.any?(&:assembled_fresh?)
  end
end
