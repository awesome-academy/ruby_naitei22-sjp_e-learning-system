class User::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_role
end
