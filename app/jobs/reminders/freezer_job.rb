module Reminders
  # Le soir, rappelle de descendre la portion du lendemain au réfrigérateur
  # si elle est au congélateur. Sans ce geste, le plan casse le vendredi.
  class FreezerJob < ApplicationJob
    queue_as :default

    def perform(date = Date.current)
      User.find_each do |user|
        target = user.nutrition_target
        next unless target&.resolved?

        tomorrow = date.tomorrow
        number = Menu::Calendar.current_week_number(tomorrow)
        next unless number

        day = Menu::Week.new(target, number).days.find { |d| d.index == tomorrow.cwday - 1 }
        next unless day&.from_freezer

        dishes = [ day.lunch&.dish&.name, day.dinner&.dish&.name ].compact.uniq
        next if dishes.empty?

        PushSubscription.broadcast(
          user: user,
          title: "Sortez les portions de demain",
          body: "#{dishes.to_sentence} — au réfrigérateur ce soir pour #{day.name.downcase}.",
          url: "/weeks/#{number}",
          tag: "freezer-#{tomorrow.iso8601}"
        )
      end
    end
  end
end
