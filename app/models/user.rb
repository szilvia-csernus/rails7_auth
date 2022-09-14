class User < ApplicationRecord
    CONFIRMATION_TOKEN_EXPIRATION = 10.minutes
    MAILER_FROM_EMAIL = "no-reply@example.com"
    PASSWORD_RESET_TOKEN_EXPIRATION = 10.minutes

    attr_accessor :current_password

    has_secure_password

    before_save :downcase_unconfirmed_email
    before_save :downcase_email

    has_many :active_sessions, dependent: :destroy

    validates :unconfirmed_email, format: {with: URI::MailTo::EMAIL_REGEXP, allow_blank: true}
    validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}, presence: true, uniqueness: true

    # this class method will be available in Rails7.1
    # This class method serves to find a user using the non-password attributes 
    # (such as email), and then authenticates that record using the password attributes. 
    # Regardless of whether a user is found or authentication succeeds, authenticate_by 
    # will take the same amount of time. This prevents timing-based enumeration attacks, 
    # wherein an attacker can determine if a password record exists even without knowing 
    # the password.
    def self.authenticate_by(attributes)
        passwords, identifiers = attributes.to_h.partition do |name, value|
        !has_attribute?(name) && has_attribute?("#{name}_digest")
        end.map(&:to_h)

        raise ArgumentError, "One or more password arguments are required" if passwords.empty?
        raise ArgumentError, "One or more finder arguments are required" if identifiers.empty?
        if (record = find_by(identifiers))
        record if passwords.count { |name, value| record.public_send(:"authenticate_#{name}", value) } == passwords.size
        else
        new(passwords)
        nil
        end
    end

    def confirm!
        if unconfirmed_or_reconfirming?
        if unconfirmed_email.present?
            return false unless update(email: unconfirmed_email, unconfirmed_email: nil)
        end
            update_columns(confirmed_at: Time.current)
        else
            # this only happens if a user tries to confirm an email address that has already been confirmed.
            false
        end
    end

    def confirmed?
        confirmed_at.present?
    end

    # creates a signed_in method to securely identify user (email address). We give an explicite
    # purpose to use to build the confirmation mailer.
    # confirmation_token ensures that confirmation links expire and cannot be reused.
    def generate_confirmation_token
        signed_id expires_in: CONFIRMATION_TOKEN_EXPIRATION, purpose: :confirm_email
    end

    def unconfirmed?
        !confirmed?
    end

    def send_confirmation_email!
        confirmation_token = generate_confirmation_token
        UserMailer.confirmation(self, confirmation_token).deliver_now
    end

    def generate_password_reset_token
        signed_id expires_in: PASSWORD_RESET_TOKEN_EXPIRATION, purpose: :reset_password
    end

    def send_password_reset_email!
        password_reset_token = generate_password_reset_token
        UserMailer.password_reset(self, password_reset_token).deliver_now
    end

    def confirmable_email
        if unconfirmed_email.present?
        unconfirmed_email
        else
        email
        end
    end
   
    def reconfirming?
        unconfirmed_email.present?
    end

    def unconfirmed_or_reconfirming?
        unconfirmed? || reconfirming?
    end


    private

    def downcase_email
        self.email = email.downcase
    end

    def downcase_unconfirmed_email
        return if unconfirmed_email.nil?
        self.unconfirmed_email = unconfirmed_email.downcase
    end
end
