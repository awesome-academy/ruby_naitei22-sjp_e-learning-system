class UsersController < ApplicationController
  before_action :authenticate_user!,
                :load_user,
                :correct_user, only: %i(show edit update)

  # GET /users/:id
  def show
    @pagy, @user_courses = pagy(
      @user.user_courses
          .with_course
          .with_status_in(params[:status])
          .recent,
      limit: Settings.page_6
    )
  end

  # GET /users/:id/edit
  def edit; end

  # PATCH/PUT /users/:id
  def update
    if @user.update user_params
      flash[:success] = t(".updated")
      redirect_to @user
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def load_user
    @user = User.find_by id: params[:id]
    return if @user

    flash[:warning] = t(".not_found")
    redirect_to root_path
  end

  def correct_user
    return if current_user == @user

    flash[:error] = t(".cannot_edit")
    redirect_to root_url
  end

  def user_params
    params.require(:user).permit(User::USER_PERMITTED)
  end
end
