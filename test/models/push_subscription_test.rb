require "test_helper"

class PushSubscriptionTest < SeededTestCase
  test "endpoint unique par utilisateur, mais le même endpoint peut appartenir à deux comptes" do
    other = User.create!(email_address: "other@example.com", password: "password")

    owner.push_subscriptions.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")

    dup = owner.push_subscriptions.new(endpoint: "https://push.example/1", p256dh_key: "c", auth_key: "d")
    assert_not dup.valid?

    other_sub = other.push_subscriptions.new(endpoint: "https://push.example/1", p256dh_key: "c", auth_key: "d")
    assert other_sub.valid?
  end

  test "broadcast n'atteint que les appareils de l'utilisateur donné" do
    other = User.create!(email_address: "other@example.com", password: "password")
    owner.push_subscriptions.create!(endpoint: "https://push.example/owner", p256dh_key: "a", auth_key: "b")
    other.push_subscriptions.create!(endpoint: "https://push.example/other", p256dh_key: "c", auth_key: "d")

    calls = []
    WebPush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      PushSubscription.broadcast(user: owner, title: "Titre", body: "Corps")
    end

    assert_equal [ "https://push.example/owner" ], calls.map { |c| c[:endpoint] }
  end
end
