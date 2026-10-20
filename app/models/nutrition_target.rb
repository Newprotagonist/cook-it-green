# La cible quotidienne — un singleton par utilisateur, comme Profile : une seule
# ligne par compte, ses quatre minimums, ses marges d'arrondi et sa répartition
# sur la journée. La modifier revient à changer cette ligne, jamais à toucher au code.
class NutritionTarget < ApplicationRecord
  MACROS = %i[protein lipid carb fiber].freeze

  # Petit-déj et collation comptent pour une prise par jour, le plat pour
  # deux (midi + soir) — structure fixe, partagée par tous les comptes.
  DEFAULT_SLOTS = [
    { slot: "breakfast", key: "petit_dej", servings_per_day: 1 },
    { slot: "dish",      key: "plat",      servings_per_day: 2 },
    { slot: "snack",     key: "collation", servings_per_day: 1 }
  ].freeze

  belongs_to :user
  has_many :meal_shares, -> { order(:position) }, dependent: :destroy
  has_many :resolved_dishes, dependent: :destroy
  has_many :resolved_fixed_meals, dependent: :destroy

  accepts_nested_attributes_for :meal_shares

  validates :protein, :lipid, :carb, :fiber,
            numericality: { greater_than: 0 }
  validate  :shares_sum_to_one

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

  # Sans répartition, slot_target (donc tout le solveur) n'a rien à lire —
  # aucun écran ne crée de meal_shares, c'est donc à la cible de s'en doter
  # elle-même la première fois qu'elle existe pour de vrai.
  def ensure_default_meal_shares!
    return if meal_shares.any?

    fractions = self.class.default_fractions
    DEFAULT_SLOTS.each_with_index do |s, position|
      f = fractions.fetch(s[:key])
      meal_shares.create!(slot: s[:slot], servings_per_day: s[:servings_per_day], position: position,
                          protein_share: f["P"], lipid_share: f["L"], carb_share: f["G"])
    end
  end

  def self.default_fractions
    @default_fractions ||= JSON.parse(Rails.root.join("db/seeds/menu_definitions.json").read)["meta"]["fractions"]
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
end
