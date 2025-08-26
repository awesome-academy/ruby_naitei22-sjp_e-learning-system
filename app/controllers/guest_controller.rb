class GuestController < ApplicationController
  skip_authorization_check only: %i(homepage)

  # GET /
  def homepage; end
end
