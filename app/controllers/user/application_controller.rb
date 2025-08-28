class User::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_role

  rescue_from CanCan::AccessDenied do
    flash[:danger] = t("errors.messages.not_authorized")
    redirect_to root_path
  end

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found
    flash[:danger] = t("errors.messages.record_not_found")
    redirect_to root_path
  end
end
