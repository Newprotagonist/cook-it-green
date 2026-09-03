# Le motif de rotation d'une semaine : quel rôle de plat à quel repas,
# quel petit-déjeuner, quelle collation. Éditable comme le reste.
class WeekPattern < ApplicationRecord
  ROLES = %w[F A B].freeze
  DAYS  = %w[Lundi Mardi Mercredi Jeudi Vendredi Samedi Dimanche].freeze

  validates :day_index, inclusion: { in: 0..6 }, uniqueness: true
  validates :lunch_role, :dinner_role, inclusion: { in: ROLES }
  validate  :no_repeat_within_day

  default_scope { order(:day_index) }

  def day_name = DAYS[day_index]

  private

  def no_repeat_within_day
    errors.add(:dinner_role, "identique au déjeuner") if lunch_role == dinner_role
  end
end
