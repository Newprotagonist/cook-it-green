class WeeksController < ApplicationController
  VIEWS = %w[planning plats courses session].freeze

  def index
    @target = NutritionTarget.current
    @season = Menu::Calendar.season_for
    @current_week = Menu::Calendar.current_week_number
    @weeks_by_season = Dish.distinct.pluck(:season, :week_number).uniq
                           .group_by(&:first)
                           .transform_values { |rows| rows.map(&:last).sort }
    @dishes_by_week = Dish.order(:letter).group_by(&:week_number)
  end

  def show
    @target = NutritionTarget.current
    return redirect_to profile_path, alert: "Définissez d'abord une cible." unless @target
    return redirect_to nutrition_targets_path, alert: "Cette cible n'a pas encore été résolue." unless @target.resolved?

    @week = Menu::Week.new(@target, params[:number].to_i)
    return redirect_to weeks_path, alert: "Semaine inconnue." if @week.roles.empty?

    @view = VIEWS.include?(params[:view]) ? params[:view] : "planning"
  end
end
