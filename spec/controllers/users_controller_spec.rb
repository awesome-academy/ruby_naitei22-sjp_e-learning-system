require "rails_helper"

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET #show" do
    context "when user is logged in" do
      before { log_in user }
      let!(:course) { create(:course) }
      let!(:user_course) { create(:user_course, user: user, course: course) }

      before { get :show, params: { id: user.id } }

      it "assigns @user" do
        expect(assigns(:user)).to eq(user)
      end

      it "assigns @user_courses" do
        expect(assigns(:user_courses)).to include(user_course)
      end

      it "responds with ok" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "when user not found" do
      before do
        log_in user
        get :show, params: { id: -1 }
      end

      it "sets flash warning" do
        expect(flash[:warning]).to be_present
      end

      it "redirects to root" do
        expect(response).to redirect_to(root_path)
      end
    end

    context "when not logged in" do
      before { get :show, params: { id: user.id } }

      it "redirects to login" do
        expect(response).to redirect_to(login_url)
      end
    end
  end

  describe "GET #new" do
    before { get :new }

    it "assigns a new user" do
      expect(assigns(:user)).to be_a_new(User)
    end

    it "renders the :new template" do
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        name: "Test User",
        email: "testuser@example.com",
        birthday: 20.years.ago.to_date,
        gender: "female",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    let(:invalid_params) do
      {
        name: "",
        email: "bad",
        extra_param: "hack"
      }
    end

    context "with valid params" do
      it "creates a new user" do
        expect {
          post :create, params: { user: valid_params }
        }.to change(User, :count).by(1)
      end

      it "creates the user with correct name" do
        post :create, params: { user: valid_params }
        expect(User.last.name).to eq "Test User"
      end

      it "creates the user with correct email" do
        post :create, params: { user: valid_params }
        expect(User.last.email).to eq "testuser@example.com"
      end

      it "creates the user with correct birthday" do
        post :create, params: { user: valid_params }
        expect(User.last.birthday).to eq 20.years.ago.to_date
      end

      it "creates the user with correct gender" do
        post :create, params: { user: valid_params }
        expect(User.last.gender).to eq "female"
      end

      it "does not allow extra unpermitted param" do
        post :create, params: { user: valid_params.merge(extra_param: "hack") }
        expect(User.last.respond_to?(:extra_param)).to be false
      end

      it "sets success flash" do
        post :create, params: { user: valid_params }
        expect(flash[:success]).to be_present
      end

      it "redirects to the created user" do
        post :create, params: { user: valid_params }
        expect(response).to redirect_to(User.last)
      end
    end

    context "with invalid params" do
      before { post :create, params: { user: invalid_params } }

      it "does not create a new user" do
        expect {
          post :create, params: { user: invalid_params }
        }.not_to change(User, :count)
      end

      it "renders the new template" do
        expect(response).to render_template(:new)
      end

      it "responds with unprocessable_entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET #edit" do
    context "when correct user" do
      before do
        log_in user
        get :edit, params: { id: user.id }
      end

      it "renders the edit template" do
        expect(response).to render_template(:edit)
      end
    end

    context "when wrong user" do
      before do
        log_in other_user
        get :edit, params: { id: user.id }
      end

      it "sets error flash" do
        expect(flash[:error]).to be_present
      end

      it "redirects to root" do
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "PATCH #update" do
    before { log_in user }

    let(:valid_params) do
      {
        id: user.id,
        user: {
          name: "New Name",
          email: "newemail@example.com",
          birthday: 20.years.ago.to_date,
          gender: "male",
          password: "newpassword",
          password_confirmation: "newpassword"
        }
      }
    end

    let(:invalid_params) do
      {
        id: user.id,
        user: {
          name: "",
          email: "invalid-email",
          extra_param: "hack"
        }
      }
    end

    context "with valid params" do
      before { patch :update, params: valid_params }

      it "updates the user's name" do
        expect(user.reload.name).to eq "New Name"
      end

      it "updates the user's email" do
        expect(user.reload.email).to eq "newemail@example.com"
      end

      it "updates the user's birthday" do
        expect(user.reload.birthday).to eq 20.years.ago.to_date
      end

      it "updates the user's gender" do
        expect(user.reload.gender).to eq "male"
      end

      it "updates the user's password" do
        expect(user.reload.authenticate("newpassword")).to be_truthy
      end
    end

    context "with invalid params" do
      before { patch :update, params: invalid_params }

      it "does not update the user's name when blank" do
        expect(user.reload.name).not_to eq ""
      end

      it "does not update the user's email when invalid" do
        expect(user.reload.email).not_to eq "invalid-email"
      end

      it "does not add extra unpermitted param" do
        expect { user.reload.extra_param }.to raise_error(NoMethodError)
      end

      it "renders the edit template" do
        patch :update, params: invalid_params
        expect(response).to render_template(:edit)
      end

      it "returns unprocessable_entity status" do
        patch :update, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
