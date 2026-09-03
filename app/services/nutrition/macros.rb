module Nutrition
  # Objet-valeur : quatre macronutriments en grammes, les kcal en découlent.
  # Convention française — `carb` est en glucides NETS (hors fibres),
  # et les fibres comptent pour 2 kcal/g.
  Macros = Struct.new(:protein, :lipid, :carb, :fiber, keyword_init: true) do
    def self.zero = new(protein: 0.0, lipid: 0.0, carb: 0.0, fiber: 0.0)

    def kcal = 4 * protein + 9 * lipid + 4 * carb + 2 * fiber

    # Ce qu'affichent la plupart des applications de suivi, qui ignorent les fibres.
    def kcal_excluding_fiber = kcal - 2 * fiber

    def +(other)
      Macros.new(protein: protein + other.protein, lipid: lipid + other.lipid,
                 carb: carb + other.carb, fiber: fiber + other.fiber)
    end

    def *(factor)
      Macros.new(protein: protein * factor, lipid: lipid * factor,
                 carb: carb * factor, fiber: fiber * factor)
    end

    def round(n = 1)
      Macros.new(protein: protein.round(n), lipid: lipid.round(n),
                 carb: carb.round(n), fiber: fiber.round(n))
    end

    def to_h = { kcal: kcal, protein: protein, lipid: lipid, carb: carb, fiber: fiber }

    def meets?(minimums)
      minimums.all? { |macro, floor| public_send(macro) >= floor - 0.05 }
    end

    def shortfalls(minimums)
      minimums.filter_map { |macro, floor| macro if public_send(macro) < floor - 0.05 }
    end
  end
end
