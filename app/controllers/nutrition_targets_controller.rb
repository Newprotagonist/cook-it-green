class NutritionTargetsController < ApplicationController
  before_action :set_target, except: :from_profile

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

  # Reprend les besoins calculés depuis le profil et les applique à la cible —
  # la crée si l'utilisateur n'en a pas encore une.
  def from_profile
    needs = current_user.profile.needs
    unless needs.usable?
      return redirect_to profile_path, alert: "Complétez le profil (âge, poids, taille, activité, objectif)."
    end

    @target = current_user.nutrition_target || current_user.build_nutrition_target
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

  # Pas de création à la volée ici : une cible sans profil renseigné n'a pas de
  # sens (ses quatre macros doivent être > 0). Seul from_profile a le droit d'en
  # créer une, à partir de besoins effectivement calculés.
  def set_target
    @target = current_user.nutrition_target
    redirect_to profile_path, alert: "Complétez d'abord votre profil pour créer une cible." unless @target
  end

  def target_params
    params.require(:nutrition_target).permit(:kcal, :protein, :lipid, :carb, :fiber,
                                             :protein_margin, :lipid_margin, :carb_margin)
  end
end
