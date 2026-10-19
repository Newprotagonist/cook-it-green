require "test_helper"

Capybara.default_max_wait_time = 5

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  seed_reference_data!
  resolve_active_target!

  # L'utilisateur seedé par db/seeds.rb — voir SeededTestCase#owner dans
  # test_helper.rb pour la même convention côté tests modèle/service.
  def owner = User.find_by!(email_address: "dev@example.com")

  def sign_in(user, password: "password")
    visit new_session_path
    fill_in "Identifiant", with: user.email_address
    fill_in "Mot de passe", with: password
    click_button "Se connecter"
    # Le redirect après connexion passe par Turbo (async) — attendre que le
    # formulaire ait disparu avant de continuer, sinon l'action suivante
    # peut arriver avant la navigation.
    assert_no_selector "input[type='password']"
  end
end
