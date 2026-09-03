module Nutrition
  # Détermine le grammage de trois ingrédients « leviers » pour qu'une recette
  # tombe sur une cible protéines / lipides / glucides, le reste étant fixe.
  #
  # Recherche exhaustive sur la grille des grammages admissibles. Le pas de 5 g
  # rend l'espace assez petit pour être parcouru entièrement — donc l'optimum est
  # garanti, contrairement à une résolution linéaire qui produit des solutions
  # hors bornes dès qu'un levier sature.
  #
  # Les cibles sont des MINIMUMS : passer dessous est bien plus grave que dépasser,
  # d'où la pénalité asymétrique.
  class Solver
    Lever = Struct.new(:key, :protein, :lipid, :carb, :min, :max, keyword_init: true) do
      def self.from(ingredient)
        new(key: ingredient.key,
            protein: ingredient.protein.to_f / 100.0,
            lipid:   ingredient.lipid.to_f   / 100.0,
            carb:    ingredient.carb.to_f    / 100.0,
            min: (ingredient.min_grams || 0).to_i,
            max: (ingredient.max_grams || 300).to_i)
      end
    end

    Result = Struct.new(:grams, :iterations, keyword_init: true)

    def initialize(step: 5, undershoot_penalty: 40)
      @step = step.to_i.clamp(1, 25)
      @penalty = undershoot_penalty.to_f
    end

    def solve(base:, levers:, target:)
      raise ArgumentError, "il faut exactement 3 leviers" unless levers.size == 3

      need_p = target[:protein].to_f - base.protein
      need_l = target[:lipid].to_f   - base.lipid
      need_c = target[:carb].to_f    - base.carb

      g0, g1, g2 = levers.map { |l| grid(l) }
      l0, l1, l2 = levers
      penalty = @penalty
      best = Float::INFINITY
      best_a, best_b, best_c = g0.first, g1.first, g2.first
      iterations = 0

      g0.each do |a|
        pa = l0.protein * a - need_p
        la = l0.lipid   * a - need_l
        ca = l0.carb    * a - need_c
        g1.each do |b|
          pb = pa + l1.protein * b
          lb = la + l1.lipid   * b
          cb = ca + l1.carb    * b
          g2.each do |c|
            iterations += 1
            d = pb + l2.protein * c
            e = d * 4
            score = e * e * (d.negative? ? penalty : 1.0)
            next if score >= best

            d = lb + l2.lipid * c
            e = d * 9
            score += e * e * (d.negative? ? penalty : 1.0)
            next if score >= best

            d = cb + l2.carb * c
            e = d * 4
            score += e * e * (d.negative? ? penalty : 1.0)
            if score < best
              best = score
              best_a, best_b, best_c = a, b, c
            end
          end
        end
      end

      Result.new(grams: { l0.key => best_a, l1.key => best_b, l2.key => best_c },
                 iterations: iterations)
    end

    private

    def grid(lever)
      low  = (lever.min.to_f / @step).ceil  * @step
      high = (lever.max.to_f / @step).floor * @step
      return [ ((lever.min + lever.max) / 2.0).round ] if high < low
      (low..high).step(@step).to_a
    end
  end
end
