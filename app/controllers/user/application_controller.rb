class User::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user
end
