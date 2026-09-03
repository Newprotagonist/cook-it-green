class RolePortion < ApplicationRecord
  validates :role, inclusion: { in: WeekPattern::ROLES }, uniqueness: true
  validates :portions, numericality: { only_integer: true, greater_than: 0 }

  def self.map = pluck(:role, :portions).to_h
end
