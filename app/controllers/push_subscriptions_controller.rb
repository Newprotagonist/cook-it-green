class PushSubscriptionsController < ApplicationController
  skip_forgery_protection only: %i[create destroy]

  def create
    sub = PushSubscription.find_or_initialize_by(endpoint: params[:endpoint])
    sub.update!(p256dh_key: params[:p256dh], auth_key: params[:auth],
                user_agent: request.user_agent)
    head :created
  end

  def destroy
    PushSubscription.find_by(endpoint: params[:endpoint])&.destroy
    head :no_content
  end
end
