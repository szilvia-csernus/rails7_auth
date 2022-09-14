class ConfirmationsController < ApplicationController
    # to prevent authenticated users from accessing pages intended for anonymus users.
    before_action :redirect_if_authenticated, only: [:create, :new]

    # To send or resend confirmation insturctions to an unconfirmed user. We still need to send 
    # a mailer when a user initially signs up. This action is requested via the 'new' form
  def create
    @user = User.find_by(email: params[:user][:email].downcase)

    if @user.present? && @user.unconfirmed?
        @user.send_confirmation_email!
      redirect_to root_path, notice: "Check your email for confirmation instructions."
    else
      redirect_to new_confirmation_path, alert: "We could not find a user with that email or that email has already been confirmed."
    end
  end

  # This action is used to confirm a user's email. This will be the page that a user lands on when 
  # they click the confirmation link in their email.
  # confirmation_token is a securely generated token to store confirmed email addresses.
  # confirmation_token is a signed_id and it's set to expire in 10 minutes.
  def edit
    @user = User.find_signed(params[:confirmation_token], purpose: :confirm_email)

    if @user.present? && @user.unconfirmed_or_reconfirming?
      if @user.confirm!
        login @user # to be automatically logged in after confirming email.
        redirect_to root_path, notice: "Your account has been confirmed."
      end
    else
        # generic error prevents leaking email addresses
        redirect_to new_confirmation_path, alert: "Something went wrong."
    end
  end

  def new
    @user = User.new
  end

end
