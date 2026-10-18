class FinalizeUserScoping < ActiveRecord::Migration[8.1]
  def change
    change_column_null :profiles, :user_id, false
    change_column_null :nutrition_targets, :user_id, false

    remove_index :push_subscriptions, :endpoint, unique: true
    change_column_null :push_subscriptions, :user_id, false
    add_index :push_subscriptions, [ :user_id, :endpoint ], unique: true
  end
end
