module Menu
  # Place une date dans la rotation : la saison donne le bloc de 4 semaines,
  # le numéro de semaine ISO choisit laquelle des 4 on cuisine.
  module Calendar
    SEASON_BY_MONTH = {
      12 => "hiver", 1 => "hiver", 2 => "hiver",
      3 => "printemps", 4 => "printemps", 5 => "printemps",
      6 => "ete", 7 => "ete", 8 => "ete",
      9 => "automne", 10 => "automne", 11 => "automne"
    }.freeze

    SEASON_LABEL = { "hiver" => "Hiver", "printemps" => "Printemps",
                     "ete" => "Été", "automne" => "Automne" }.freeze

    module_function

    def season_for(date = Date.current) = SEASON_BY_MONTH.fetch(date.month)

    def week_numbers_for(season)
      Dish.for_season(season).distinct.pluck(:week_number).sort
    end

    def current_week_number(date = Date.current)
      numbers = week_numbers_for(season_for(date))
      return nil if numbers.empty?
      numbers[date.cweek % numbers.size]
    end

    # 0 = lundi, cohérent avec WeekPattern#day_index (Date#wday donne 0 = dimanche).
    def today_day_index(date = Date.current) = (date.wday + 6) % 7

    # Avant 15 h, on vise le déjeuner à venir ou en cours ; après, le dîner.
    def now_slot(time = Time.current) = time.hour < 15 ? :lunch : :dinner

    # La session de batch a lieu le dimanche qui précède la semaine de menu.
    def next_batch_session(date = Date.current)
      date.sunday? ? date : date.next_occurring(:sunday)
    end

    def label_for(season) = SEASON_LABEL.fetch(season, season)
  end
end
