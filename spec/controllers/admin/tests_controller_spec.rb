require "rails_helper"

RSpec.describe Admin::TestsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin) { create(:user, role: :admin) }
  let(:limit) { Settings.test.page_number }
  let(:testrec) { create(:test, name: "Alpha Suite", duration: 5) }

  let(:ability) do
    obj = Object.new
    obj.extend(CanCan::Ability)
    obj.can :manage, Test
    obj.can :manage, Question
    obj.can :manage, Answer
    obj
  end

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in admin
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(controller).to receive(:authorize_admin_area).and_return(true)
  end

  describe "GET #index" do
    let!(:tests) { create_list(:test, limit + 3) }

    context "page=1 without search" do
      before { get :index, params: { page: 1 } }

      it "responds with 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "assigns @tests limited by Settings.test.page_number" do
        expect(assigns(:tests).size).to eq(limit)
      end

      it "assigns @pagy count equals total tests" do
        expect(assigns(:pagy).count).to eq(Test.count)
      end

      it "assigns recent order on first page" do
        expect(assigns(:tests)).to eq(Test.by_name(nil).recent.limit(limit))
      end
    end

    context "page=2 without search" do
      before { get :index, params: { page: 2 } }

      it "assigns remaining items" do
        remaining = [Test.count - limit, 0].max
        expected_size = [remaining, limit].min
        expect(assigns(:tests).size).to eq(expected_size)
      end
    end

    context "search by name" do
      let!(:matched)   { create(:test, name: "Ruby Mastery") }
      let!(:unmatched) { create(:test, name: "Elixir Journey") }

      before { get :index, params: { page: 1, search: "Ruby" } }

      it "includes matched" do
        expect(assigns(:tests)).to include(matched)
      end

      it "excludes unmatched" do
        expect(assigns(:tests)).not_to include(unmatched)
      end
    end
  end

  describe "GET #show" do
    let!(:q1) { create(:question, test: testrec) }
    let!(:q2) { create(:question, test: testrec) }
    let!(:a1) { create(:answer, question: q1) }

    it "responds with 200 OK" do
      get :show, params: { id: testrec.id }
      expect(response).to have_http_status(:ok)
    end

    it "assigns @questions for the test" do
      get :show, params: { id: testrec.id }
      expect(assigns(:questions)).to match_array([q1, q2])
    end

    it "raises RecordNotFound when id = -1" do
      expect { get :show, params: { id: -1 } }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #new" do
    before { get :new }

    it "responds with 200 OK" do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    let(:params_ok) { { name: "Clean Architecture", description: "MA", duration: 10, max_attempts: 3 } }

    it "creates test with matching name" do
      post :create, params: { test: params_ok }
      expect(Test.order(:created_at).last.name).to eq("Clean Architecture")
    end

    it "sets flash success i18n" do
      post :create, params: { test: params_ok }
      expect(flash[:success]).to eq(I18n.t("admin.tests.create_success"))
    end

    it "redirects to show" do
      post :create, params: { test: params_ok }
      t = Test.order(:created_at).last
      expect(response).to redirect_to(admin_test_path(t))
    end

    context "when save fails" do
      before { allow_any_instance_of(Test).to receive(:save).and_return(false) }

      it "renders new with 422" do
        post :create, params: { test: params_ok }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets flash.now danger i18n" do
        post :create, params: { test: params_ok }
        expect(flash.now[:danger]).to eq(I18n.t("admin.tests.create_failed"))
      end
    end
  end

  describe "GET #edit" do
    it "responds with 200 OK" do
      get :edit, params: { id: testrec.id }
      expect(response).to have_http_status(:ok)
    end

    it "raises RecordNotFound when id = -1" do
      expect { get :edit, params: { id: -1 } }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "PATCH #update" do
    let(:update_params) { { name: "Refactor Legacy", description: "Improve", duration: 7 } }

    it "updates name matching params" do
      patch :update, params: { id: testrec.id, test: update_params }
      expect(testrec.reload.name).to eq("Refactor Legacy")
    end

    it "sets flash success i18n" do
      patch :update, params: { id: testrec.id, test: update_params }
      expect(flash[:success]).to eq(I18n.t("admin.tests.update_success"))
    end

    it "redirects to show" do
      patch :update, params: { id: testrec.id, test: update_params }
      expect(response).to redirect_to(admin_test_path(testrec))
    end

    context "when update fails" do
      before { allow_any_instance_of(Test).to receive(:update).and_return(false) }

      it "renders edit with 422" do
        patch :update, params: { id: testrec.id, test: update_params }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets flash.now danger i18n" do
        patch :update, params: { id: testrec.id, test: update_params }
        expect(flash.now[:danger]).to eq(I18n.t("admin.tests.update_failed"))
      end
    end

    it "raises RecordNotFound when id = -1" do
      expect {
        patch :update, params: { id: -1, test: update_params }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "DELETE #destroy" do
    let!(:target) { create(:test) }

    it "deletes test (count -1)" do
      expect {
        delete :destroy, params: { id: target.id }
      }.to change(Test, :count).by(-1)
    end

    it "sets flash success i18n on success" do
      delete :destroy, params: { id: target.id }
      expect(flash[:success]).to eq(I18n.t("admin.tests.delete_success"))
    end

    it "redirects to index on success" do
      delete :destroy, params: { id: target.id }
      expect(response).to redirect_to(admin_tests_path)
    end

    context "when destroy fails" do
      before { allow_any_instance_of(Test).to receive(:destroy).and_return(false) }

      it "sets flash danger i18n" do
        delete :destroy, params: { id: target.id }
        expect(flash[:danger]).to eq(I18n.t("admin.tests.delete_failed"))
      end

      it "redirects to show on failure" do
        delete :destroy, params: { id: target.id }
        expect(response).to redirect_to(admin_test_path(target))
      end
    end

    it "raises RecordNotFound when id = -1" do
      expect { delete :destroy, params: { id: -1 } }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
