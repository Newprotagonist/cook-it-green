require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "le compte démo ne peut pas s'abonner aux notifications push" do
    demo = User.create!(email_address: "demo@cookitgreen.app", password: "password", demo: true)
    sign_in_as(demo)

    post push_subscription_path, params: { endpoint: "https://push.example/demo", p256dh: "a", auth: "b" }

    assert_response :no_content
    assert_empty demo.push_subscriptions
  end
end
