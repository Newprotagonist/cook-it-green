class ResolvedFixedMeal < ApplicationRecord
  belongs_to :nutrition_target
  belongs_to :fixed_meal

  def macros
    Nutrition::Macros.new(protein: protein.to_f, lipid: lipid.to_f,
                          carb: carb.to_f, fiber: fiber.to_f)
  end

  def lines
    by_key = Ingredient.where(key: grams.keys).index_by(&:key)
    grams.sort_by { |_, g| -g.to_f }.map { |k, g| [ by_key[k], g.to_f ] }.reject { |i, _| i.nil? }
  end
end
