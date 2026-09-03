# La cible quotidienne. Chaque enregistrement porte ses quatre minimums,
# ses marges d'arrondi et sa répartition sur la journée : changer d'objectif
# revient à créer ou modifier une ligne, jamais à toucher au code.
class NutritionTarget < ApplicationRecord
  SOURCES = %w[manual computed preset].freeze
  MACROS  = %i[protein lipid carb fiber].freeze

  has_many :meal_shares, -> { order(:position) }, dependent: :destroy
  has_many :resolved_dishes, dependent: :destroy
  has_many :resolved_fixed_meals, dependent: :destroy

  accepts_nested_attributes_for :meal_shares

  validates :name, presence: true
  validates :protein, :lipid, :carb, :fiber,
            numericality: { greater_than: 0 }
  validates :source, inclusion: { in: SOURCES }
  validate  :shares_sum_to_one

  after_save :ensure_single_active, if: :saved_change_to_active?

  scope :active, -> { where(active: true) }

  def self.current
    active.first || order(created_at: :desc).first
  end

  # Le plancher calorique imposé par les quatre minimums, convention française.
  def floor_kcal
    4 * protein.to_f + 9 * lipid.to_f + 4 * carb.to_f + 2 * fiber.to_f
  end

  # Cible d'UNE prise du créneau demandé (breakfast, dish, snack).
  def slot_target(slot)
    share = meal_shares.detect { |s| s.slot == slot.to_s }
    raise ArgumentError, "créneau inconnu : #{slot}" unless share
    {
      protein: protein.to_f * protein_margin.to_f * share.protein_share.to_f,
      lipid:   lipid.to_f   * lipid_margin.to_f   * share.lipid_share.to_f,
      carb:    carb.to_f    * carb_margin.to_f    * share.carb_share.to_f
    }
  end

  def resolved? = resolved_at.present?

  def stale?
    return true unless resolved?
    resolved_at < updated_at || resolved_dishes.count != Dish.count
  end

  def macro_minimums
    { protein: protein.to_f, lipid: lipid.to_f, carb: carb.to_f, fiber: fiber.to_f }
  end

  private

  # Somme des parts x nombre de prises = 1 pour chaque macronutriment,
  # sinon la journée ne retombe pas sur la cible.
  def shares_sum_to_one
    return if meal_shares.empty?
    %i[protein_share lipid_share carb_share].each do |attr|
      total = meal_shares.sum { |s| s.public_send(attr).to_f * s.servings_per_day }
      next if (total - 1.0).abs < 0.005
      errors.add(:meal_shares, "#{attr} : la somme fait #{total.round(4)} au lieu de 1")
    end
  end

  def ensure_single_active
    return unless active?
    self.class.where.not(id: id).update_all(active: false)
  end
end
