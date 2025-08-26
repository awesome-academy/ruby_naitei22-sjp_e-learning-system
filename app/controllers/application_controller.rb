class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include SessionsHelper
  include Pagy::Backend

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  check_authorization unless: :devise_controller?

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

  rescue_from CanCan::AccessDenied do
    flash[:danger] = t("flash.not_authorized")
    redirect_to root_path
  end

  private

  def authorize_user_area
    authorize! :access, :user_area
  rescue CanCan::AccessDenied
    flash[:danger] = t("flash.not_authorized")
    redirect_to root_path
  end

  def authorize_admin_area
    authorize! :access, :admin_dashboard
  rescue CanCan::AccessDenied
    flash[:danger] = t("flash.not_authorized")
    redirect_to root_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i(name birthday gender))
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: %i(name birthday gender))
  end
end
