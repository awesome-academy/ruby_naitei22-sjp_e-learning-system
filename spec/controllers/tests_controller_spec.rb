require "rails_helper"

RSpec.describe Admin::TestsController, type: :controller do
  let(:admin){create(:user, :admin)}
  let!(:test_record){create(:test)}

  context "when a guest user is accessing" do
    it "redirects GET #index to the login page" do
      get :index
      expect(response).to redirect_to(login_path)
    end

    it "redirects POST #create to the login page" do
      post :create, params: {test: attributes_for(:test)}
      expect(response).to redirect_to(login_path)
    end
  end

  context "when an admin user is logged in" do
    before do
      allow(controller).to receive(:current_user).and_return(admin)
    end

    describe "GET #index" do
      before{get :index}

      it "returns an HTTP 200 OK status" do
        expect(response).to have_http_status(:ok)
      end

      it "assigns all tests to @tests" do
        expect(assigns(:tests)).to include(test_record)
      end

      it "renders the 'index' template" do
        expect(response).to render_template(:index)
      end
    end

    describe "GET #show" do
      context "with a valid ID" do
        before{get :show, params: {id: test_record.id}}

        it "assigns the requested test to @test" do
          expect(assigns(:test)).to eq(test_record)
        end

        it "renders the 'show' template" do
          expect(response).to render_template(:show)
        end
      end

      context "with an invalid ID" do
        before{get :show, params: {id: -1}}

        it "redirects to the tests index page" do
          expect(response).to redirect_to(admin_tests_path)
        end

        it "sets a danger flash message" do
          expect(flash[:danger]).to be_present
        end
      end
    end

    describe "GET #new" do
      before{get :new}

      it "assigns a new Test to @test" do
        expect(assigns(:test)).to be_a_new(Test)
      end

      it "renders the 'new' template" do
        expect(response).to render_template(:new)
      end
    end

    describe "POST #create" do
      context "with valid parameters" do
        let(:valid_attributes){attributes_for(:test)}

        it "creates a new Test" do
          expect do
            post :create, params: {test: valid_attributes}
          end.to change(Test, :count).by(1)
        end

        it "creates a test with the correct attributes" do
          post :create, params: {test: valid_attributes}
          expect(assigns(:test)).to have_attributes(valid_attributes)
        end

        it "redirects to the newly created test's page" do
          post :create, params: {test: valid_attributes}
          expect(response).to redirect_to(admin_test_path(Test.last))
        end

        it "sets a success flash message" do
          post :create, params: {test: valid_attributes}
          expect(flash[:success]).to be_present
        end
      end

      context "with invalid parameters" do
        let(:invalid_attributes){attributes_for(:test, name: "")}

        it "does not create a new Test" do
          expect do
            post :create, params: {test: invalid_attributes}
          end.not_to change(Test, :count)
        end

        it "re-renders the 'new' template" do
          post :create, params: {test: invalid_attributes}
          expect(response).to render_template(:new)
        end

        it "returns an unprocessable_entity HTTP status" do
          post :create, params: {test: invalid_attributes}
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "GET #edit" do
      it "renders the 'edit' template" do
        get :edit, params: {id: test_record.id}
        expect(response).to render_template(:edit)
      end
    end

    describe "PATCH #update" do
      context "with valid parameters" do
        let(:new_attributes){{name: "Updated Test Name"}}
        before do
          patch :update,
                params: {id: test_record.id, test: new_attributes}
        end

        it "updates the requested test's attribute" do
          expect(test_record.reload.name).to eq("Updated Test Name")
        end

        it "updates the test with the correct attributes" do
          expect(assigns(:test)).to have_attributes(new_attributes)
        end

        it "redirects to the test's page" do
          expect(response).to redirect_to(admin_test_path(test_record))
        end

        it "sets a success flash message" do
          expect(flash[:success]).to be_present
        end
      end

      context "with invalid parameters" do
        let(:invalid_attributes){{name: ""}}
        before do
          patch :update,
                params: {id: test_record.id, test: invalid_attributes}
        end

        it "does not update the test's attribute" do
          expect(test_record.reload.name).not_to eq("")
        end

        it "re-renders the 'edit' template" do
          expect(response).to render_template(:edit)
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested test" do
        expect do
          delete :destroy, params: {id: test_record.id}
        end.to change(Test, :count).by(-1)
      end

      it "redirects to the tests index page" do
        delete :destroy, params: {id: test_record.id}
        expect(response).to redirect_to(admin_tests_path)
      end

      it "sets a success flash message" do
        delete :destroy, params: {id: test_record.id}
        expect(flash[:success]).to be_present
      end

      it "sets a danger flash message if the test cannot be destroyed" do
        allow_any_instance_of(Test).to receive(:destroy).and_return(false)
        delete :destroy, params: {id: test_record.id}
        expect(flash[:danger]).to be_present
      end
    end
  end
end
