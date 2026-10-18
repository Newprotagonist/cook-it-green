class AddUserRefToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_reference :profiles, :user, null: true, foreign_key: true
  end
end
