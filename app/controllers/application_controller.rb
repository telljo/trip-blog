class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend
  include Pagy::Frontend
  before_action :set_current_request_details
  before_action :authenticate

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:notice] = "You are not authorized to perform this action."
    redirect_back(fallback_location: trips_url)
  end

  private
    def pundit_user
      Current.user
    end

    def authenticate
      if session_record = Session.find_by_id(cookies.signed[:session_token])
        Current.session = session_record
      else
        redirect_to sign_in_path
      end
    end

    def set_current_request_details
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
      if session_record = Session.find_by_id(cookies.signed[:session_token])
        Current.session = session_record
      end
    end
end
