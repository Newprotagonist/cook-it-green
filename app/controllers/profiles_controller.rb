class ProfilesController < ApplicationController
  def show
    @profile = Profile.current
    @needs = @profile.needs if @profile.complete? && @profile.goal && @profile.activity_level
    @target = NutritionTarget.current
    @targets = NutritionTarget.order(:created_at)
  end

  def update
    @profile = Profile.current
    if @profile.update(profile_params)
      redirect_to profile_path, notice: "Profil mis à jour."
    else
      @needs = nil
      @target = NutritionTarget.current
      @targets = NutritionTarget.order(:created_at)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:sex, :age, :weight_kg, :height_cm, :body_fat_pct,
                                    :activity_level_id, :goal_id)
  end
end
