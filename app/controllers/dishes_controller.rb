class DishesController < ApplicationController
  def show
    @dish = Dish.includes(dish_components: :ingredient).find_by!(key: params[:key])
    @target = NutritionTarget.current
    @resolved = @dish.resolved_for(@target) if @target
    @week = Menu::Week.new(@target, @dish.week_number) if @target
  end
end
