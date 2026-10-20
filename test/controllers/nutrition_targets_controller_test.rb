require "test_helper"

class NutritionTargetsControllerTest < ActionDispatch::IntegrationTest
  seed_reference_data!

  # Régression directe : from_profile posait kcal/protéines/lipides/glucides/
  # fibres mais ne créait jamais de meal_shares (aucun écran ne le fait non
  # plus) — tout nouveau compte invité plantait au premier recalcul.
  test "from_profile crée une cible utilisable, avec sa répartition, pour un compte tout neuf" do
    guest = User.create!(email_address: "guest@example.com", password: "password")
    sign_in_as(guest)
    guest.profile.update!(sex: "female", age: 29, weight_kg: 62, height_cm: 168,
                          activity_level: ActivityLevel.find_by(key: "modere"),
                          goal: Goal.find_by(key: "maintien"))

    post from_profile_nutrition_target_path

    assert_redirected_to nutrition_target_path
    target = guest.reload.nutrition_target
    assert target.present?
    assert_equal 3, target.meal_shares.count
    assert_nothing_raised { Menu::Recalculator.new(target).call }
  end
end
