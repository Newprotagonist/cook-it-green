class AddStorageModeToDishesAndAssemblyToDishComponents < ActiveRecord::Migration[8.1]
  def up
    add_column :dishes, :storage_mode, :string, null: false, default: "frais"
    execute "UPDATE dishes SET storage_mode = CASE WHEN freezable THEN 'congelable' ELSE 'frais' END"
    remove_column :dishes, :freezable

    add_column :dish_components, :assembled_fresh, :boolean, null: false, default: false
  end

  def down
    add_column :dishes, :freezable, :boolean, null: false, default: true
    execute "UPDATE dishes SET freezable = (storage_mode != 'frais')"
    remove_column :dishes, :storage_mode
    remove_column :dish_components, :assembled_fresh
  end
end
