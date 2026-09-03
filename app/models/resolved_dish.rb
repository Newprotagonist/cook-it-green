# Sortie du solveur pour un plat et une cible donnés.
class ResolvedDish < ApplicationRecord
  belongs_to :nutrition_target
  belongs_to :dish

  def macros
    Nutrition::Macros.new(protein: protein.to_f, lipid: lipid.to_f,
                          carb: carb.to_f, fiber: fiber.to_f)
  end

  # [[Ingredient, grammes]] trié du plus lourd au plus léger.
  def lines
    keys = grams.keys
    by_key = Ingredient.where(key: keys).index_by(&:key)
    grams.sort_by { |_, g| -g.to_f }.map { |k, g| [ by_key[k], g.to_f ] }.reject { |i, _| i.nil? }
  end

  def lever_keys = dish.lever_components.map { |c| c.ingredient.key }

  def within_tolerance?(g = 3.0)
    [ protein_deviation, lipid_deviation, carb_deviation ].all? { |d| d.to_f.abs <= g }
  end
end
