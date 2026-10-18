class NutritionTargetsController < ApplicationController
  before_action :set_target

  def show
  end

  def update
    if @target.update(target_params)
      redirect_to nutrition_target_path,
                  notice: "Cible modifiée. Elle doit être recalculée pour que le menu suive."
    else
      redirect_to nutrition_target_path, alert: @target.errors.full_messages.to_sentence
    end
  end

  # Reprend les besoins calculés depuis le profil et les applique à la cible.
  def from_profile
    needs = Profile.current.needs
    unless needs.usable?
      return redirect_to profile_path, alert: "Complétez le profil (âge, poids, taille, activité, objectif)."
    end

    @target.update!(needs.target_attributes)
    redirect_to nutrition_target_path, notice: "Besoins appliqués à votre cible."
  end

  # Le solveur tourne ~800 ms sur les 48 plats et les 24 recettes fixes :
  # assez rapide pour rester synchrone, assez lourd pour ne pas s'exécuter
  # à chaque affichage de page.
  def recalculate
    report = Menu::Recalculator.new(@target).call
    notice = "Recalcul terminé en #{report.duration_ms} ms — #{report.dishes} plats, #{report.fixed_meals} recettes fixes."
    if report.ok?
      redirect_to nutrition_target_path, notice: "#{notice} Les 112 journées atteignent tous les minimums."
    else
      redirect_to nutrition_target_path,
                  alert: "#{notice} Attention : #{report.shortfalls.size} journée(s) sous un minimum."
    end
  end

  private

  def set_target = @target = NutritionTarget.current

  def target_params
    params.require(:nutrition_target).permit(:kcal, :protein, :lipid, :carb, :fiber,
                                             :protein_margin, :lipid_margin, :carb_margin)
  end
end
