class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, uniqueness: { scope: :user_id }
  validates :p256dh_key, :auth_key, presence: true

  # Diffuse à tous les appareils enregistrés d'un utilisateur et élague les
  # abonnements morts.
  def self.broadcast(user:, title:, body:, url: "/", tag: nil)
    payload = {
      title: title, body: body, url: url, tag: tag,
      icon: ApplicationController.helpers.versioned_icon_path("icon-192.png"),
      badge: ApplicationController.helpers.versioned_icon_path("badge-96.png")
    }.compact

    user.push_subscriptions.find_each do |sub|
      begin
        WebPush.payload_send(
          message: JSON.generate(payload),
          endpoint: sub.endpoint,
          p256dh: sub.p256dh_key,
          auth: sub.auth_key,
          vapid: vapid_credentials
        )
      rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
        sub.destroy
      end
    end
  end

  def self.vapid_credentials
    creds = Rails.application.credentials.vapid
    { subject: creds&.dig(:subject) || "mailto:admin@example.com",
      public_key: creds&.dig(:public_key), private_key: creds&.dig(:private_key) }
  end
end
