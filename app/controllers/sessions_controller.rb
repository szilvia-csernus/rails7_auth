class SessionsController < ApplicationController
  before_action :redirect_if_authenticated, only: [:create, :new]
  before_action :authenticate_user!, only: [:destroy]

  # login and logout methods are coming from the Authentication Concern.
  def create
    # The login form is passed a scope: :user option so that params are namespaced [:user]
    @user = User.authenticate_by(email: params[:user][:email].downcase, password: params[:user][:password])
    if @user
      if @user.unconfirmed?
        redirect_to new_confirmation_path, alert: "Incorrect email or password."

      else
        # we set after_login_path before login, because login calls reset_session which 
        # will delete session@user = User.find_by(email: params[:user][:email].downcase)
        after_login_path = session[:user_return_to] || root_path 
        active_session = login @user
        remember(active_session) if params[:user][:remember_me] == "1"
        redirect_to after_login_path, notice: "Signed in."
      end
    else
      # we set this alert when user is unconfirmed, to prevent leaking email addresses.
      flash.now[:alert] = "Incorrect email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    forget_active_session
    logout
    redirect_to root_path, notice: "Signed out."
  end

  def new
  end

end
