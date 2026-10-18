require "test_helper"

class Reminders::FreezerJobTest < MenuTestCase
  # Régression : les gardes de la boucle par utilisateur doivent `next`, pas
  # `return` — un `return` interromprait tous les utilisateurs suivants dès
  # que le premier n'a pas de cible résolue.
  test "un utilisateur sans cible résolue ne bloque pas les suivants" do
    not_ready = User.create!(email_address: "not-ready@example.com", password: "password")
    # not_ready a un profil (créé automatiquement à la création du compte)
    # mais aucune cible : ignoré par la garde `target&.resolved?`.

    ready = build_resolved_user("ready@example.com")
    ready.push_subscriptions.create!(endpoint: "https://push.example/ready", p256dh_key: "a", auth_key: "b")

    friday_eve = Date.current.next_occurring(:thursday)

    calls = []
    WebPush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      Reminders::FreezerJob.perform_now(friday_eve)
    end

    assert_equal [ "https://push.example/ready" ], calls.map { |c| c[:endpoint] }
  end

  private

  def build_resolved_user(email)
    user = User.create!(email_address: email, password: "password")
    target = user.build_nutrition_target(owner.nutrition_target.attributes.slice(
      "kcal", "protein", "lipid", "carb", "fiber", "protein_margin", "lipid_margin", "carb_margin"))
    target.save!(validate: false)
    owner.nutrition_target.meal_shares.each do |s|
      target.meal_shares.create!(s.attributes.except("id", "nutrition_target_id", "created_at", "updated_at"))
    end
    Menu::Recalculator.new(target).call
    user
  end
end
