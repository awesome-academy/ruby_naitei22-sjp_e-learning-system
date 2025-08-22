class SessionsController < ApplicationController
  before_action :check_auth, only: %i(omniauth)
  before_action :check_user, only: %i(omniauth)

  def omniauth
    reset_session
    log_in @user
    remember @user
    flash[:success] = t(".login_success")
    redirect_back_or root_path
  end

  private

  def check_auth
    @auth = request.env["omniauth.auth"]
    return if @auth

    flash[:danger] = t(".auth_failed")
    render :new, status: :unprocessable_entity
  end

  def check_user
    @user = User.find_or_create_from_auth_hash @auth
    return if @user

    flash[:danger] = t(".created_failed")
    render :new, status: :unprocessable_entity
  end
end
