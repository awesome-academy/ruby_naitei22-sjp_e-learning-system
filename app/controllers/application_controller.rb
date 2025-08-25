class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include SessionsHelper
  include Pagy::Backend

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  def set_locale
    allowed = I18n.available_locales.map(&:to_s)

    I18n.locale =
      if allowed.include?(params[:locale])
        params[:locale]
      else
        I18n.default_locale
      end
  end

  def default_url_options
    {locale: I18n.locale}
  end

  def respond_modal_with(*args, &)
    options = args.extract_options!
    options[:responder] = ModalResponder
    respond_with(*args, options, &)
  end

  private

  def logged_in_user
    return if logged_in?

    store_location
    flash[:danger] = t("flash.please_log_in")
    redirect_to login_url
  end

  def ensure_user_role
    return if current_user&.user?

    flash[:danger] = t(".error.not_authenticated")
    redirect_to root_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i(name birthday gender))
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: %i(name birthday gender))
  end
end
