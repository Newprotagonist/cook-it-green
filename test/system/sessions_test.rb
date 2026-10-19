require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  test "se connecter avec les bons identifiants mène à la rotation annuelle" do
    sign_in(owner)

    assert_text "Seize semaines"
  end

  test "un mauvais mot de passe reste sur l'écran de connexion avec une erreur" do
    visit new_session_path
    fill_in "Identifiant", with: owner.email_address
    fill_in "Mot de passe", with: "mauvais mot de passe"
    click_button "Se connecter"

    assert_text "incorrect"
    assert_no_text "Seize semaines"
  end

  test "se déconnecter (desktop) revient à l'écran de connexion" do
    sign_in(owner)

    click_button "Déconnexion"

    assert_selector "input[type='password']"
  end

  test "se déconnecter (mobile) revient à l'écran de connexion" do
    page.driver.browser.manage.window.resize_to(390, 844)
    begin
      sign_in(owner)

      find("summary", text: "Réglages").click
      # <details> est un widget natif : le clic sur <summary> l'ouvre de façon
      # synchrone côté navigateur, mais laisser Capybara attendre explicitement
      # que le bouton soit bien là avant de cliquer évite un flake occasionnel
      # observé sur CI chargée (même symptôme que noté dans ci.yml).
      assert_selector "button", text: "Déconnexion"
      click_button "Déconnexion"

      assert_selector "input[type='password']"
    ensure
      # Selenium réutilise la même fenêtre entre les tests : une taille qui
      # fuit sur le test suivant masque du contenu desktop ailleurs.
      page.driver.browser.manage.window.resize_to(1400, 1400)
    end
  end
end
