class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_one :nutrition_target, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  after_create { create_profile!(sex: "male") }
end
