require "rails_helper"

RSpec.describe GuestController, type: :controller do
  describe "GET #homepage" do
    before { get :homepage }

    it "responds with 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the homepage template" do
      expect(response).to render_template(:homepage)
    end
  end
end
