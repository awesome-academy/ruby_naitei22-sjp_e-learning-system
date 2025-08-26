require "rails_helper"

RSpec.describe Admin::TestsController, type: :controller do
  let!(:admin_user) { create(:user, role: "admin") }
  let!(:test1) { create(:test, name: "Test A", created_at: 2.days.ago) }
  let!(:test2) { create(:test, name: "Test B", created_at: 1.day.ago) }

  def login_as_admin
    session[:user_id] = admin_user.id
  end

  before do
    login_as_admin
  end

  # Test cho GET #index
  describe "GET #index" do
    context "without search params" do
      before { get :index }
      it "assigns all tests ordered by recent to @tests" do
        expect(assigns(:tests)).to eq([test2, test1])
      end
      it "renders the index template" do
        expect(response).to render_template(:index)
      end
    end
    context "with search params" do
      it "filters tests by name" do
        get :index, params: { search: "Test A" }
        expect(assigns(:tests)).to eq([test1])
      end
    end
  end

  # Test cho GET #show
  describe "GET #show" do
    let!(:question1) { create(:question, test: test1) }
    before { get :show, params: { id: test1.id } }

    it "assigns questions for the test to @questions" do
      expect(assigns(:questions)).to eq([question1])
    end
    it "renders the show template" do
      expect(response).to render_template(:show)
    end
  end

  # Test cho GET #new
  describe "GET #new" do
    before { get :new }

    it "assigns a new test to @test" do
      expect(assigns(:test)).to be_a_new(Test)
    end
    it "renders the new template" do
      expect(response).to render_template(:new)
    end
  end

  # Test cho POST #create
  describe "POST #create" do
    let(:valid_params) do
      { test: attributes_for(:test) }
    end
    context "with valid params" do
      it "creates a new test" do
        expect { post :create, params: valid_params }.to change(Test, :count).by(1)
      end
      it "redirects to the test show page" do
        post :create, params: valid_params
        expect(response).to redirect_to(admin_test_path(Test.last))
      end
      it "sets a success flash message" do
        post :create, params: valid_params
        expect(flash[:success]).to eq(I18n.t("admin.tests.create_success"))
      end
    end
    context "with invalid params" do
      let(:invalid_params) do
        { test: attributes_for(:test, name: nil) }
      end
      it "does not create a new test" do
        expect { post :create, params: invalid_params }.not_to change(Test, :count)
      end
      it "renders the new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
      it "sets a danger flash message" do
        post :create, params: invalid_params
        expect(flash[:danger]).to eq(I18n.t("admin.tests.create_failed"))
      end
    end
  end

  # Test cho GET #edit
  describe "GET #edit" do
    before { get :edit, params: { id: test1.id } }
    it "assigns the requested test to @test" do
      expect(assigns(:test)).to eq(test1)
    end
    it "renders the edit template" do
      expect(response).to render_template(:edit)
    end
  end

  # Test cho PATCH #update
  describe "PATCH #update" do
    let(:new_name) { "Updated Test Name" }
    let(:valid_update_params) do
      { id: test1.id, test: { name: new_name } }
    end
    context "with valid params" do
      it "updates the test" do
        patch :update, params: valid_update_params
        test1.reload
        expect(test1.name).to eq(new_name)
      end
      it "redirects to the test show page" do
        patch :update, params: valid_update_params
        expect(response).to redirect_to(admin_test_path(test1))
      end
      it "sets a success flash message" do
        patch :update, params: valid_update_params
        expect(flash[:success]).to eq(I18n.t("admin.tests.update_success"))
      end
    end
    context "with invalid params" do
      let(:invalid_update_params) do
        { id: test1.id, test: { name: nil } }
      end
      it "does not update the test" do
        patch :update, params: invalid_update_params
        test1.reload
        expect(test1.name).not_to be_nil
      end
      it "renders the edit template" do
        patch :update, params: invalid_update_params
        expect(response).to render_template(:edit)
      end
      it "sets a danger flash message" do
        patch :update, params: invalid_update_params
        expect(flash[:danger]).to eq(I18n.t("admin.tests.update_failed"))
      end
    end
  end

  # Test cho DELETE #destroy
  describe "DELETE #destroy" do
    context "when destroy is successful" do
      it "destroys the requested test" do
        expect { delete :destroy, params: { id: test1.id } }.to change(Test, :count).by(-1)
      end
      it "sets a success flash message" do
        delete :destroy, params: { id: test1.id }
        expect(flash[:success]).to eq(I18n.t("admin.tests.delete_success"))
      end
      it "redirects to the tests index" do
        delete :destroy, params: { id: test1.id }
        expect(response).to redirect_to(admin_tests_path)
      end
    end
    context "when destroy fails" do
      before do
        allow_any_instance_of(Test).to receive(:destroy).and_return(false)
        delete :destroy, params: { id: test1.id }
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.tests.delete_failed"))
      end
      it "redirects to the test show page" do
        expect(response).to redirect_to(admin_test_path(test1))
      end
    end
  end

  # Test cho before_actions
  describe "before_action :set_test" do
    context "when test is not found" do
      before { get :show, params: { id: -1 } }
      it "redirects to admin tests path" do
        expect(response).to redirect_to(admin_tests_path)
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.tests.not_found"))
      end
    end
  end
end
