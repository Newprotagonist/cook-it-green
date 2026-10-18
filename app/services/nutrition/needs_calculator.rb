module Nutrition
  # Estime la dépense énergétique et en déduit une cible quotidienne.
  #
  # Mifflin-St Jeor par défaut ; Katch-McArdle dès que le taux de masse grasse
  # est connu, car il s'appuie sur la masse maigre et se trompe moins.
  class NeedsCalculator
    attr_reader :profile, :settings

    def initialize(profile, settings: NutritionSetting.current)
      @profile  = profile
      @settings = settings
    end

    def usable? = profile.complete? && profile.activity_level && profile.goal

    def method_name
      lean_mass ? "Katch-McArdle" : "Mifflin-St Jeor"
    end

    # Métabolisme de base, en kcal.
    def basal_metabolic_rate
      return 370 + 21.6 * lean_mass if lean_mass

      base = 10 * profile.weight_kg.to_f + 6.25 * profile.height_cm.to_f - 5 * profile.age.to_i
      base + (profile.sex == "male" ? 5 : -161)
    end

    def total_expenditure
      basal_metabolic_rate * profile.activity_level.factor.to_f
    end

    def kcal
      (total_expenditure * (1 + profile.goal.kcal_delta.to_f)).round
    end

    # La majoration végétale s'applique ICI, une seule fois : les objectifs
    # stockent une recommandation omnivore. La compter aussi dans Goal
    # donnerait des cibles de 2,5 g/kg et plus, hors de tout sens physiologique.
    def protein_g_per_kg
      profile.goal.protein_g_per_kg.to_f * settings.plant_protein_multiplier.to_f
    end

    def fiber
      (settings.fiber_per_1000_kcal.to_f * kcal / 1000.0).round
    end

    def protein = (profile.weight_kg.to_f * protein_g_per_kg).round

    def lipid
      floor_from_weight = profile.weight_kg.to_f * profile.goal.lipid_g_per_kg.to_f
      floor_from_share  = settings.min_lipid_kcal_share.to_f * kcal / 9.0
      [ floor_from_weight, floor_from_share ].max.round
    end

    # Les glucides prennent ce qui reste. Si le reste tombe sous le plancher
    # physiologique, on rend des calories en abaissant les lipides plutôt que
    # de laisser les glucides s'effondrer.
    def carb
      remaining = (kcal - 4 * protein - 9 * lipid - 2 * fiber) / 4.0
      [ remaining, carb_floor ].max.round
    end

    def lipid_adjusted
      return lipid if (kcal - 4 * protein - 9 * lipid - 2 * fiber) / 4.0 >= carb_floor
      ((kcal - 4 * protein - 4 * carb_floor - 2 * fiber) / 9.0).round
    end

    def carb_floor = profile.weight_kg.to_f * settings.min_carb_g_per_kg.to_f

    def target_attributes
      { kcal: kcal, protein: protein, lipid: lipid_adjusted, carb: carb, fiber: fiber }
    end

    def summary
      { method: method_name, bmr: basal_metabolic_rate.round, tdee: total_expenditure.round,
        kcal: kcal, protein_g_per_kg: protein_g_per_kg.round(2),
        activity: profile.activity_level.name, goal: profile.goal.name }
    end

    private

    def lean_mass
      return nil if profile.body_fat_pct.blank? || profile.body_fat_pct.to_f <= 3
      profile.weight_kg.to_f * (1 - profile.body_fat_pct.to_f / 100.0)
    end
  end
end
