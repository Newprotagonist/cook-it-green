class PushSubscriptionsController < ApplicationController
  skip_forgery_protection only: %i[create destroy]

  # Un même appareil (ex. tablette familiale) peut porter l'abonnement d'un
  # utilisateur puis être utilisé par un autre — l'endpoint ne peut valablement
  # appartenir qu'à un seul compte à la fois.
  def create
    return head :no_content if current_user.demo?

    PushSubscription.where(endpoint: params[:endpoint]).where.not(user_id: current_user.id).destroy_all
    sub = current_user.push_subscriptions.find_or_initialize_by(endpoint: params[:endpoint])
    sub.update!(p256dh_key: params[:p256dh], auth_key: params[:auth],
                user_agent: request.user_agent)
    head :created
  end

  def destroy
    current_user.push_subscriptions.find_by(endpoint: params[:endpoint])&.destroy
    head :no_content
  end
end
