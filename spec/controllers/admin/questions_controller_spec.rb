require "rails_helper"

RSpec.describe Admin::QuestionsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin)   { create(:user, role: :admin) }
  let(:testrec) { create(:test, duration: 5) }

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

  describe "GET #new" do
    before { get :new, params: { test_id: testrec.id } }

    it "builds a single_choice question" do
      expect(assigns(:question).question_type).to eq("single_choice")
    end

    it "builds default number of answers" do
      expect(assigns(:question).answers.size).to eq(Settings.question.answer_defaults_number)
    end

    it "responds with 200 OK" do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        content: "What is Ruby?",
        question_type: :single_choice,
        answers_attributes: [
          { content: "A language", correct: true },
          { content: "A gemstone", correct: false }
        ]
      }
    end

    it "persists question with matching content" do
      post :create, params: { test_id: testrec.id, question: valid_params }
      expect(testrec.questions.order(:created_at).last.content).to eq("What is Ruby?")
    end

    it "sets flash success (i18n)" do
      post :create, params: { test_id: testrec.id, question: valid_params }
      expect(flash[:success]).to eq(I18n.t("admin.questions.create.success"))
    end

    it "redirects to admin_test_path" do
      post :create, params: { test_id: testrec.id, question: valid_params }
      expect(response).to redirect_to(admin_test_path(testrec))
    end

    context "when save fails" do
      before { allow_any_instance_of(Question).to receive(:save).and_return(false) }

      it "renders :new with 422" do
        post :create, params: { test_id: testrec.id, question: valid_params }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets flash.now danger (i18n)" do
        post :create, params: { test_id: testrec.id, question: valid_params }
        expect(flash.now[:danger]).to eq(I18n.t("admin.questions.create.failure"))
      end
    end

    it "raises RecordNotFound when test_id = -1" do
      expect {
        post :create, params: { test_id: -1, question: valid_params }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #show" do
    let!(:question) { create(:question, test: testrec, content: "Q1") }

    it "responds with 200 OK" do
      get :show, params: { test_id: testrec.id, id: question.id }
      expect(response).to have_http_status(:ok)
    end

    it "raises RecordNotFound when id = -1" do
      expect {
        get :show, params: { test_id: testrec.id, id: -1 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #edit" do
    let!(:question) { create(:question, test: testrec, content: "Q1") }

    it "responds with 200 OK" do
      get :edit, params: { test_id: testrec.id, id: question.id }
      expect(response).to have_http_status(:ok)
    end

    it "raises RecordNotFound when id = -1" do
      expect {
        get :edit, params: { test_id: testrec.id, id: -1 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "PATCH #update" do
    let!(:question) { create(:question, test: testrec, content: "Old") }

    let(:update_params) do
      {
        content: "Updated content",
        question_type: :single_choice,
        answers_attributes: [
          { id: nil, content: "Ans 1", correct: true }
        ]
      }
    end

    it "updates content to match params" do
      patch :update, params: { test_id: testrec.id, id: question.id, question: update_params }
      expect(question.reload.content).to eq("Updated content")
    end

    it "sets flash success (i18n)" do
      patch :update, params: { test_id: testrec.id, id: question.id, question: update_params }
      expect(flash[:success]).to eq(I18n.t("admin.questions.update.success"))
    end

    it "redirects to admin_test_path" do
      patch :update, params: { test_id: testrec.id, id: question.id, question: update_params }
      expect(response).to redirect_to(admin_test_path(testrec))
    end

    context "when update fails" do
      before { allow_any_instance_of(Question).to receive(:update).and_return(false) }

      it "renders :edit with 422" do
        patch :update, params: { test_id: testrec.id, id: question.id, question: update_params }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets flash.now danger (i18n)" do
        patch :update, params: { test_id: testrec.id, id: question.id, question: update_params }
        expect(flash.now[:danger]).to eq(I18n.t("admin.questions.update.failure"))
      end
    end

    it "raises RecordNotFound when id = -1" do
      expect {
        patch :update, params: { test_id: testrec.id, id: -1, question: update_params }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "DELETE #destroy" do
    let!(:question) { create(:question, test: testrec) }

    it "deletes question (count -1)" do
      expect {
        delete :destroy, params: { test_id: testrec.id, id: question.id }
      }.to change(Question, :count).by(-1)
    end

    it "sets flash success (i18n)" do
      delete :destroy, params: { test_id: testrec.id, id: question.id }
      expect(flash[:success]).to eq(I18n.t("admin.questions.destroy.success"))
    end

    it "redirects to admin_test_path" do
      delete :destroy, params: { test_id: testrec.id, id: question.id }
      expect(response).to redirect_to(admin_test_path(testrec))
    end

    context "when destroy fails" do
      before { allow_any_instance_of(Question).to receive(:destroy).and_return(false) }

      it "sets flash danger (i18n)" do
        delete :destroy, params: { test_id: testrec.id, id: question.id }
        expect(flash[:danger]).to eq(I18n.t("admin.questions.destroy.failure"))
      end
    end

    it "raises RecordNotFound when id = -1" do
      expect {
        delete :destroy, params: { test_id: testrec.id, id: -1 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
