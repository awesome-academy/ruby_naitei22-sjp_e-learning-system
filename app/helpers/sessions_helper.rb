module SessionsHelper
  def log_in user
    session[:user_id] = user.id
  end

  def current_user
    @current_user ||= find_user_from_session || find_user_from_cookies
  end

  def current_user? user
    user == current_user
  end

  def logged_in?
    current_user.present?
  end

  def log_out
    forget current_user if current_user
    reset_session
    @current_user = nil
  end

  def remember user
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  def forget user
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  def remember_session user
    user.remember
    session[:session_token] = user.remember_token
  end

  def is_user?
    current_user&.user?
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  def redirect_back_or default
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  def logged_in_user
    return if logged_in?

    store_location
    flash[:danger] = t("flash.please_log_in")
    redirect_to login_url
  end

  def admin_user
    return if current_user.admin?

    flash[:danger] = t("flash.not_authorized")
    redirect_to root_path
  end

  private

  def find_user_from_session
    user_id = session[:user_id]
    return unless user_id

    user = User.find_by(id: user_id)
    return unless user

    session_token = session[:session_token]
    return if session_token && !user.authenticated?(session_token)

    user
  end

  def find_user_from_cookies
    user_id = cookies.signed[:user_id]
    return unless user_id

    user = User.find_by(id: user_id)
    return unless user&.authenticated?(cookies[:remember_token])

    log_in user
    user
  end
end
