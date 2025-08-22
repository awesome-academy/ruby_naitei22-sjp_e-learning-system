# app/controllers/users/omniauth_callbacks_controller.rb
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.find_or_create_from_auth_hash(auth_hash)

    if @user.persisted?
      handle_successful_authentication
    else
      handle_failed_authentication
    end
  end

  private

  def handle_successful_authentication
    flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: "Google"
    sign_in_and_redirect @user, event: :authentication
  end

  def handle_failed_authentication
    session["devise.google_data"] = auth_hash.except("extra")
    alert_message = @user.errors.full_messages.join("\n")
    redirect_to new_user_registration_url, alert: alert_message
  end

  def auth_hash
    request.env["omniauth.auth"]
  end
end
