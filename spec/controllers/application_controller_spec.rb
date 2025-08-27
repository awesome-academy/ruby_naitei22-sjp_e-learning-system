require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  describe "#set_locale" do
    it "sets the locale from params" do
      controller.params = { locale: "en" }
      controller.send(:set_locale)
      expect(I18n.locale).to eq(:en)
    end
  end

  describe "#default_url_options" do
    controller do
      def index
        render plain: "Test"
      end
    end

    it "returns a hash with the current locale" do
      get :index, params: { locale: "en" }
      expect(controller.default_url_options).to eq({ locale: :en })
    end
  end

  describe "#logged_in_user" do
    controller do
      before_action :logged_in_user
      def index
        render plain: "Test"
      end
    end

    context "when a user is logged in" do
      let!(:user) { create(:user) }
      before do
        session[:user_id] = user.id
        get :index
      end

      it "does not redirect" do
        expect(response).to be_successful
      end
    end

    context "when a user is not logged in" do
      before { get :index }

      it "redirects to the login page" do
        expect(response).to redirect_to(login_url)
      end
      it "sets a flash message" do
        expect(flash[:danger]).to eq(I18n.t("flash.please_log_in"))
      end
    end
  end

  describe "#ensure_user_role" do
    controller do
      before_action :ensure_user_role
      def index
        render plain: "Test"
      end
    end

    context "when the user has a user role" do
      let!(:user) { create(:user, role: "user") }
      before do
        session[:user_id] = user.id
        get :index
      end

      it "does not redirect" do
        expect(response).to be_successful
      end
    end

    context "when the user does not have a user role" do
      let!(:admin) { create(:user, role: "admin") }
      before do
        session[:user_id] = admin.id
        get :index
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
      it "sets a flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.courses.authenticate_admin.not_authorized"))
      end
    end
  end
end
