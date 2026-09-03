module Menu
  # Recalcule l'intégralité du menu pour une cible : 48 plats et 12 recettes
  # fixes déclinées sur 4 saisons. Le solveur coûte trop cher pour tourner à
  # chaque requête, les résultats sont donc persistés.
  class Recalculator
    Report = Struct.new(:dishes, :fixed_meals, :duration_ms, :shortfalls,
                        :worst_deviations, keyword_init: true) do
      def ok? = shortfalls.empty?
    end

    def initialize(target)
      @target = target
      @resolver = Resolver.new(target)
    end

    def call
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      dish_rows = fixed_rows = 0

      ActiveRecord::Base.transaction do
        Dish.includes(dish_components: :ingredient).find_each do |dish|
          upsert(ResolvedDish, @resolver.resolve_dish(dish), %i[nutrition_target_id dish_id])
          dish_rows += 1
        end

        FixedMeal.includes(fixed_meal_components: :ingredient).find_each do |meal|
          Ingredient::SEASONS.each do |season|
            attrs = @resolver.resolve_fixed_meal(meal, season)
            upsert(ResolvedFixedMeal, attrs, %i[nutrition_target_id fixed_meal_id season])
            fixed_rows += 1
          end
        end

        @target.update_column(:resolved_at, Time.current)
      end

      elapsed = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
      Report.new(dishes: dish_rows, fixed_meals: fixed_rows, duration_ms: elapsed,
                 shortfalls: shortfalls, worst_deviations: worst_deviations)
    end

    # Les 112 journées de l'année : chacune doit atteindre les quatre minimums.
    def shortfalls
      minimums = @target.macro_minimums
      Dish.distinct.pluck(:week_number).sort.flat_map do |number|
        Week.new(@target, number).days.filter_map do |day|
          missing = day.totals.shortfalls(minimums)
          next if missing.empty?
          { week: number, day: day.name, macros: missing }
        end
      end
    end

    def worst_deviations(limit = 5)
      ResolvedDish.where(nutrition_target: @target).includes(:dish)
        .sort_by { |r| -[ r.protein_deviation, r.lipid_deviation, r.carb_deviation ].map { |d| d.to_f.abs }.max }
        .first(limit)
        .map do |r|
          { dish: r.dish.name,
            protein: r.protein_deviation.to_f, lipid: r.lipid_deviation.to_f,
            carb: r.carb_deviation.to_f }
        end
    end

    private

    def upsert(klass, attrs, keys)
      record = klass.find_or_initialize_by(attrs.slice(*keys))
      record.assign_attributes(attrs)
      record.save!
    end
  end
end
