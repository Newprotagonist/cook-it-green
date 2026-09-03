# Singleton : les constantes du calcul des besoins. Les stocker en base
# plutôt qu'en constantes Ruby permet de les ajuster sans redéployer.
class NutritionSetting < ApplicationRecord
  validates :fiber_per_1000_kcal, :plant_protein_multiplier,
            :min_carb_g_per_kg, :min_lipid_kcal_share,
            numericality: { greater_than: 0 }

  def self.current
    first || create!
  end
end
