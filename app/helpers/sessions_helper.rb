module SessionsHelper
  def admin_user
    return if current_user.admin?

    flash[:danger] = t("flash.not_authorized")
    redirect_to root_path
  end
end
