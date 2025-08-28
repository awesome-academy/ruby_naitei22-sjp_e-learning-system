require "rails_helper"

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "123456",
      info: { email: "user@example.com", name: "Google User" }
    )
  end

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["omniauth.auth"] = auth_hash
  end

  describe "GET #google_oauth2" do
    context "when user is found and persisted" do
      let!(:user) { create(:user, email: "user@example.com") }

      before do
        allow(User).to receive(:from_omniauth).and_return(user)
        get :google_oauth2
      end

      it "signs in the user" do
        expect(controller.current_user).to eq(user)
      end

      it "redirects to after sign in path" do
        expect(response).to redirect_to(root_path)
      end

      it "sets success flash with Google provider" do
        expect(flash[:notice]).to eq(I18n.t("devise.omniauth_callbacks.success", kind: "Google"))
      end
    end

    context "when user is not persisted" do
      let(:user) { build(:user) }

      before do
        allow(User).to receive(:from_omniauth).and_return(user)
        get :google_oauth2
      end

      it "stores google data in session without extra" do
        expect(session["devise.google_data"]).to eq(auth_hash.except(:extra))
      end

      it "redirects to new user session path" do
        expect(response).to redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET #failure" do
    before { process :failure, method: :get }

    it "sets flash alert with i18n message" do
      expect(flash[:alert]).to eq(I18n.t("sessions.omniauth.auth_failed"))
    end

    it "redirects to new user session path" do
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
