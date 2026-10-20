require "test_helper"

class DemoResetJobTest < SeededTestCase
  test "réinitialise chaque compte démo sans toucher aux comptes normaux" do
    demo = User.create!(email_address: "demo@cookitgreen.app", password: "password", demo: true)
    demo.profile.update!(age: 40, weight_kg: 90, height_cm: 190)

    DemoResetJob.perform_now

    assert_equal 29, demo.profile.reload.age
    assert demo.nutrition_target.reload.resolved?
    assert_not owner.demo?
  end
end
