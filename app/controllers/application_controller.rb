class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Application mono-utilisateur : pas de modèle User, pas de Devise.
  # Un identifiant partagé unique protège l'ensemble de l'app. Le but est la
  # défense en profondeur contre la découverte d'URL (crawlers, logs CT, liens
  # fuités) et les scanners — ce n'est pas un système de comptes.
  #
  # La garde porte sur la présence de la variable d'environnement, PAS sur
  # Rails.env.production?, pour que le même chemin de code soit exerçable en local.
  #
  # Les routes internes à Rails (le /up de Kamal, le manifeste et le service worker
  # PWA) n'héritent pas d'ApplicationController et restent donc accessibles sans auth.
  if ENV["BASIC_AUTH_USER"].present?
    http_basic_authenticate_with(
      name: ENV["BASIC_AUTH_USER"],
      password: ENV["BASIC_AUTH_PASSWORD"]
    )
  end
end
