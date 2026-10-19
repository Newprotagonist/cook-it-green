require "application_system_test_case"

# Régression directe sur le bug qu'on a le plus à coeur d'éviter depuis le
# passage au multi-utilisateur : qu'un compte voie, même partiellement, le
# profil, la cible ou le menu d'un autre compte.
class MultiUserIsolationTest < ApplicationSystemTestCase
  test "un compte fraîchement invité ne voit ni le profil ni le menu du propriétaire" do
    guest = User.create!(email_address: "invite@example.com", password: "password")

    sign_in(guest)

    visit root_path
    assert_text "Aucune cible résolue pour l'instant."

    visit profile_path
    assert_equal "", find_field("Âge").value
    assert_equal "", find_field("Poids").value
    assert_equal "", find_field("Taille").value
  end
end
