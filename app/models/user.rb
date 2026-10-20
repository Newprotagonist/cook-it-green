class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_one :nutrition_target, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy

  scope :not_demo, -> { where(demo: false) }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  after_create { create_profile!(sex: "male") }

  # Identifiants publics sur le portfolio : n'importe quel visiteur peut
  # modifier le profil/la cible du compte démo librement, mais jamais son
  # mot de passe ni le compte lui-même — voir users.rake. Cette méthode
  # ramène les données mutables à un état propre (appelée chaque nuit par
  # Solid Queue, voir config/recurring.yml) sans jamais toucher au mot de
  # passe : les identifiants publiés doivent rester valables indéfiniment.
  def reset_demo_content!
    raise "reset_demo_content! appelé sur un compte non-démo" unless demo?

    profile.update!(sex: "female", age: 29, weight_kg: 62, height_cm: 168,
                    activity_level: ActivityLevel.find_by(key: "modere"),
                    goal: Goal.find_by(key: "maintien"))
    needs = profile.needs
    target = nutrition_target || build_nutrition_target
    target.update!(needs.target_attributes)
    target.ensure_default_meal_shares!
    Menu::Recalculator.new(target).call
    push_subscriptions.destroy_all
  end
end
