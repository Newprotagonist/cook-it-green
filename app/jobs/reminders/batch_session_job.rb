module Reminders
  # La veille de la session : annonce les trois plats et surtout les trempages,
  # qui doivent démarrer le soir même pour être prêts le lendemain.
  class BatchSessionJob < ApplicationJob
    queue_as :default

    def perform(date = Date.current)
      User.not_demo.find_each do |user|
        target = user.nutrition_target
        next unless target&.resolved?

        number = Menu::Calendar.current_week_number(date.next_week)
        next unless number

        week = Menu::Week.new(target, number)
        next if week.roles.empty?

        soaks = week.roles.values
                    .flat_map { |dish| dish.dish_components.map(&:ingredient) }
                    .select { |i| i.soak_time.present? }
                    .uniq(&:key)

        body = "Semaine #{number} : #{week.roles.values.map(&:name).to_sentence}."
        body += " À mettre à tremper ce soir : #{soaks.map(&:name).to_sentence}." if soaks.any?

        PushSubscription.broadcast(
          user: user,
          title: "Session de batch demain",
          body: body,
          url: "/weeks/#{number}?view=session",
          tag: "batch-#{number}"
        )
      end
    end
  end
end
