class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    # Une ligne par navigateur/appareil. Pas de User : l'app est mono-utilisateur,
    # `.broadcast` diffuse à toutes les lignes.
    create_table :push_subscriptions do |t|
      t.string :endpoint,   null: false
      t.string :p256dh_key, null: false
      t.string :auth_key,   null: false
      t.string :user_agent
      t.timestamps
    end
    add_index :push_subscriptions, :endpoint, unique: true
  end
end
