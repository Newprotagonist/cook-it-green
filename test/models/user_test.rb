require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "reset_demo_content! refuse un compte non marqué démo" do
    user = User.create!(email_address: "not-demo@example.com", password: "password")
    assert_raises(RuntimeError) { user.reset_demo_content! }
  end

  test "reset_demo_content! produit un profil complet, une cible résolue, et purge les abonnements push" do
    self.class.seed_reference_data!
    user = User.create!(email_address: "demo@cookitgreen.app", password: "password", demo: true)
    user.push_subscriptions.create!(endpoint: "https://push.example/stale", p256dh_key: "a", auth_key: "b")

    user.reset_demo_content!

    assert user.profile.reload.complete?
    assert user.nutrition_target.reload.resolved?
    assert_empty user.push_subscriptions.reload
  end
end
