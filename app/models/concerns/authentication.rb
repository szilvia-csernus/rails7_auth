# This concern provides an interface for loogging user in and out. As we load it into
# Application Controller, it will be used across the whole application.

module Authentication extend ActiveSupport::Concern

  included do
    before_action :current_user
    helper_method :current_user # to have access to current_user in the views.
    helper_method :user_signed_in?
  end

  # login will first reset the session to account for 'session fixation'.
  # The user's ID stored in the session cookie cryptographically signed to make it
  # temperproof. It is also encrypted so anyone with access to it can't read its contents.
  def login(user)
    reset_session
    active_session = user.active_sessions.create!(user_agent: request.user_agent, ip_address: request.ip)
    session[:current_active_session_id] = active_session.id

    active_session
  end

  def forget_active_session
    cookies.delete :remember_token
  end

  def logout
    active_session = ActiveSession.find_by(id: session[:current_active_session_id])
    reset_session
    active_session.destroy! if active_session.present?
  end

  def authenticate_user!
    store_location    # original request url, if it was a GET request
    redirect_to login_path, alert: "You need to login to access that page." unless user_signed_in?
  end

  def redirect_if_authenticated
    redirect_to root_path, alert: "You are already logged in." if user_signed_in?
  end
  
  def remember(active_session)
    cookies.permanent.encrypted[:remember_token] = active_session.remember_token
  end

  private

  def current_user
    Current.user = if session[:current_active_session_id].present?
      # '&' is added only because it may return nil, as we are able to delete other
      # ascive_session records.
      ActiveSession.find_by(id: session[:current_active_session_id])&.user
    elsif cookies.permanent.encrypted[:remember_token].present?
      ActiveSession.find_by(remember_token: cookies.permanent.encrypted[:remember_token])&.user
    end
  end

  def user_signed_in?
    Current.user.present?
  end

  def store_location
    # request.local? as a condition prevents redirecting to an external application
    session[:user_return_to] = request.original_url if request.get? && request.local?
  end

end