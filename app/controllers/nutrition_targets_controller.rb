class NutritionTargetsController < ApplicationController
  before_action :set_target, only: %i[update activate recalculate]

  def index
    @targets = NutritionTarget.order(:created_at)
    @current = NutritionTarget.current
  end

  def create
    @target = NutritionTarget.new(target_params.merge(source: "manual"))
    copy_shares_from_current(@target)
    if @target.save
      redirect_to nutrition_targets_path, notice: "Cible créée. Lancez le recalcul pour l'appliquer."
    else
      redirect_to nutrition_targets_path, alert: @target.errors.full_messages.to_sentence
    end
  end

  def update
    if @target.update(target_params)
      redirect_to nutrition_targets_path,
                  notice: "Cible modifiée. Elle doit être recalculée pour que le menu suive."
    else
      redirect_to nutrition_targets_path, alert: @target.errors.full_messages.to_sentence
    end
  end

  # Reprend les besoins calculés depuis le profil et en fait une nouvelle cible.
  def from_profile
    profile = Profile.current
    needs = profile.needs
    unless needs.usable?
      return redirect_to profile_path, alert: "Complétez le profil (âge, poids, taille, activité, objectif)."
    end

    target = NutritionTarget.new(needs.target_attributes)
    copy_shares_from_current(target)
    if target.save
      redirect_to nutrition_targets_path, notice: "Cible créée depuis votre profil : #{target.name}"
    else
      redirect_to profile_path, alert: target.errors.full_messages.to_sentence
    end
  end

  def activate
    @target.update!(active: true)
    redirect_back fallback_location: nutrition_targets_path, notice: "« #{@target.name} » est la cible active."
  end

  # Le solveur tourne ~800 ms sur les 48 plats et les 24 recettes fixes :
  # assez rapide pour rester synchrone, assez lourd pour ne pas s'exécuter
  # à chaque affichage de page.
  def recalculate
    report = Menu::Recalculator.new(@target).call
    notice = "Recalcul terminé en #{report.duration_ms} ms — #{report.dishes} plats, #{report.fixed_meals} recettes fixes."
    if report.ok?
      redirect_to nutrition_targets_path, notice: "#{notice} Les 112 journées atteignent tous les minimums."
    else
      redirect_to nutrition_targets_path,
                  alert: "#{notice} Attention : #{report.shortfalls.size} journée(s) sous un minimum."
    end
  end

  private

  def set_target = @target = NutritionTarget.find(params[:id])

  def target_params
    params.require(:nutrition_target).permit(:name, :kcal, :protein, :lipid, :carb, :fiber,
                                             :protein_margin, :lipid_margin, :carb_margin)
  end

  # La répartition sur la journée se transmet d'une cible à l'autre ;
  # on ne la redemande que si l'utilisateur veut la modifier.
  def copy_shares_from_current(target)
    source = NutritionTarget.current or return
    source.meal_shares.each do |share|
      target.meal_shares.build(share.attributes.except("id", "nutrition_target_id", "created_at", "updated_at"))
    end
  end
end
