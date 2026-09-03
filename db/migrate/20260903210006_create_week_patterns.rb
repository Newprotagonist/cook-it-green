class CreateWeekPatterns < ActiveRecord::Migration[8.1]
  def change
    # Le motif de rotation hebdomadaire, lui aussi éditable.
    create_table :week_patterns do |t|
      t.integer :day_index, null: false          # 0 = lundi
      t.string  :lunch_role,  null: false        # F | A | B
      t.string  :dinner_role, null: false
      t.integer :breakfast_position, null: false
      t.integer :snack_position,     null: false
      t.boolean :frozen, null: false, default: false
      t.text    :revival
      t.timestamps
    end
    add_index :week_patterns, :day_index, unique: true

    create_table :role_portions do |t|
      t.string  :role, null: false               # F | A | B
      t.integer :portions, null: false
      t.text    :description
      t.timestamps
    end
    add_index :role_portions, :role, unique: true
  end
end
