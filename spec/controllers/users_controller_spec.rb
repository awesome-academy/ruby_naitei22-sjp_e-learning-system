require "rails_helper"

RSpec.describe UsersController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET #show - displaying user courses with pagination" do
    let!(:courses) { create_list(:course, 12) }

    before do
      courses.each { |c| create(:user_course, user: user, course: c) }
    end

    context "when page=1" do
      before { get :show, params: { id: user.id, page: 1 } }

      it "responds with 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "assigns @user to requested user" do
        expect(assigns(:user)).to eq(user)
      end

      it "limits @user_courses by Settings.page_6" do
        expect(assigns(:user_courses).size).to eq(Settings.page_6)
      end

      it "assigns most recent user_courses" do
        expected = user.user_courses.recent.limit(Settings.page_6)
        expect(assigns(:user_courses)).to eq(expected)
      end
    end

    context "when page=2" do
      before { get :show, params: { id: user.id, page: 2 } }

      it "assigns remaining user_courses" do
        expected_size = user.user_courses.size - Settings.page_6
        expect(assigns(:user_courses).size).to eq(expected_size)
      end
    end

    context "when user not found" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          get :show, params: { id: -1 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET #edit - editing user" do
    before { get :edit, params: { id: user.id } }

    it "responds with 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "assigns @user" do
      expect(assigns(:user)).to eq(user)
    end
  end

  describe "PATCH #update - updating user" do
    let(:params) { { name: "New Name", email: "new@example.com" } }

    context "when params are valid" do
      before { patch :update, params: { id: user.id, user: params } }

      it "updates the user with matching attributes" do
        expect(user.reload.slice(:name, :email)).to eq(params.stringify_keys)
      end

      it "sets success flash using I18n" do
        expect(flash[:success]).to eq(I18n.t("users.update.updated"))
      end

      it "redirects to user show page" do
        expect(response).to redirect_to(user)
      end
    end

    context "when params are invalid" do
      before { patch :update, params: { id: user.id, user: { name: "" } } }

      it "does not update the user" do
        expect(user.reload.name).not_to eq("")
      end

      it "renders edit template" do
        expect(response).to render_template(:edit)
      end

      it "responds with 422 Unprocessable Entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when user not found" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          patch :update, params: { id: -1, user: params }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
