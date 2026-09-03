class RenameFrozenOnWeekPatterns < ActiveRecord::Migration[8.1]
  # `frozen?` est défini par Active Record (DangerousAttributeError).
  # `from_freezer` dit d'ailleurs mieux ce que la colonne signifie :
  # ce jour-là, les portions sortent du congélateur.
  def change
    rename_column :week_patterns, :frozen, :from_freezer
  end
end
