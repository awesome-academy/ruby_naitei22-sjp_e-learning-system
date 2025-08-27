class Admin::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!

  rescue_from CanCan::AccessDenied do
    flash[:danger] = t("errors.messages.not_authorized")
    redirect_to root_path
  end

  private

  def authorize_admin!
    authorize! :access, :admin_namespace
  end
end
