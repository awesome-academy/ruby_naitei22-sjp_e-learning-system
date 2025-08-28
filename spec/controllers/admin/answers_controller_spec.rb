require "rails_helper"

RSpec.describe Admin::AnswersController, type: :controller do
  include Devise::Test::ControllerHelpers
  render_views

  let(:admin)    { create(:user, role: :admin) }
  let(:testrec)  { create(:test) }
  let(:question) { create(:question, test: testrec) }

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
    it "responds with 200 OK" do
      get :new, params: { test_id: testrec.id, question_id: question.id }
      expect(response).to have_http_status(:ok)
    end

    it "renders answers/_form partial" do
      get :new, params: { test_id: testrec.id, question_id: question.id }
      expect(response).to render_template(partial: "answers/_form")
    end

    it "raises RecordNotFound when question id = -1" do
      expect {
        get :new, params: { test_id: testrec.id, question_id: -1 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST #create" do
    let(:params_ok) { { content: "Option A", correct: true } }

    it "creates answer with attributes matching params" do
      post :create, params: {
        test_id: testrec.id, question_id: question.id, answer: params_ok
      }
      created = Answer.order(:created_at).last
      expect(created.slice("content", "correct")).to eq(
        "content" => "Option A", "correct" => true
      )
    end

    it "sets flash success (i18n: admin.answers.create.success)" do
      post :create, params: {
        test_id: testrec.id, question_id: question.id, answer: params_ok
      }
      expect(flash[:success]).to eq(I18n.t("admin.answers.create.success"))
    end

    it "redirects to admin_test_question_path" do
      post :create, params: {
        test_id: testrec.id, question_id: question.id, answer: params_ok
      }
      expect(response).to redirect_to(admin_test_question_path(testrec, question))
    end

    context "when save fails" do
      let!(:q) { create(:question, test: testrec) }  # tạo sẵn trước khi stub

      it "sets flash error (i18n: admin.answers.create.failure)" do
        allow_any_instance_of(Answer).to receive(:save).and_return(false)
        post :create, params: {
          test_id: testrec.id, question_id: q.id, answer: params_ok
        }
        expect(flash[:error]).to eq(I18n.t("admin.answers.create.failure"))
      end
    end

    it "raises RecordNotFound when question id = -1" do
      expect {
        post :create, params: { test_id: testrec.id, question_id: -1, answer: params_ok }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "DELETE #destroy" do
    let!(:answer) { create(:answer, question: question) }

    it "deletes the answer (count changes -1)" do
      expect {
        delete :destroy, params: {
          test_id: testrec.id, question_id: question.id, id: answer.id
        }
      }.to change(Answer, :count).by(-1)
    end

    it "sets flash success (i18n: admin.answers.destroy.success)" do
      delete :destroy, params: {
        test_id: testrec.id, question_id: question.id, id: answer.id
      }
      expect(flash[:success]).to eq(I18n.t("admin.answers.destroy.success"))
    end

    it "redirects to admin_test_question_path" do
      delete :destroy, params: {
        test_id: testrec.id, question_id: question.id, id: answer.id
      }
      expect(response).to redirect_to(admin_test_question_path(testrec, question))
    end

    it "sets flash error when destroy fails" do
      allow_any_instance_of(Answer).to receive(:destroy).and_return(false)
      delete :destroy, params: {
        test_id: testrec.id, question_id: question.id, id: answer.id
      }
      expect(flash[:error]).to eq(I18n.t("admin.answers.destroy.failure"))
    end

    it "raises RecordNotFound when answer id = -1" do
      expect {
        delete :destroy, params: { test_id: testrec.id, question_id: question.id, id: -1 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
