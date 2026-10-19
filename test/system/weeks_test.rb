require "application_system_test_case"

class WeeksTest < ApplicationSystemTestCase
  setup { sign_in(owner) }

  test "la page d'accueil liste les 16 semaines de la rotation annuelle" do
    visit root_path

    assert_text "Seize semaines"
    (1..16).each { |n| assert_link "Semaine #{n}" }
  end

  test "le détail d'une semaine propose planning, plats, liste de courses et session" do
    visit week_path(number: 1)

    assert_text "Semaine 1"
    assert_selector "table", text: "Lundi"

    click_on "Plats & recettes"
    # Texte source "Pour une portion", transformé en capitales par CSS
    # (text-transform: uppercase) — Selenium rend le texte visible, pas le DOM brut.
    assert_text "POUR UNE PORTION"

    click_on "Liste de courses"
    assert_text "Quantités pour"

    click_on "Session de 3 h"
    assert_text "La veille"
  end
end
