require "rails_helper"

RSpec.describe Admin::AnswersController, type: :controller do
  let!(:admin_user) { create(:user, role: "admin") }
  let!(:test) { create(:test) }

  let!(:question) { create(:question, test: test) }

  let!(:answer) { create(:answer, question: question) }

  def login_as_admin
    session[:user_id] = admin_user.id
  end

  before do
    login_as_admin
  end

  # Test cho POST #create
  describe "POST #create" do
    context "with valid params" do
      let(:valid_params) do
        { test_id: test.id, question_id: question.id,
          answer: { content: "New answer", correct: true } }
      end

      it "creates a new answer" do
        expect { post :create, params: valid_params }.to change(Answer, :count).by(1)
      end
      it "sets a success flash message" do
        post :create, params: valid_params
        expect(flash[:success]).to eq(I18n.t("admin.answers.create.success"))
      end
      it "redirects to the question show page" do
        post :create, params: valid_params
        expect(response).to redirect_to(admin_test_question_path(test, question))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        { test_id: test.id, question_id: question.id,
          answer: { content: nil, correct: true } }
      end

      it "does not create a new answer" do
        expect { post :create, params: invalid_params }.not_to change(Answer, :count)
      end
      it "sets an error flash message" do
        post :create, params: invalid_params
        expect(flash[:error]).to eq(I18n.t("admin.answers.create.failure"))
      end
      it "redirects to the question show page" do
        post :create, params: invalid_params
        expect(response).to redirect_to(admin_test_question_path(test, question))
      end
    end
  end

  # Test cho DELETE #destroy
  describe "DELETE #destroy" do
    context "when destroy is successful" do
      it "destroys the requested answer" do
        expect { delete :destroy, params: { test_id: test.id, question_id: question.id, id: answer.id } }.to change(Answer, :count).by(-1)
      end
      it "sets a success flash message" do
        delete :destroy, params: { test_id: test.id, question_id: question.id, id: answer.id }
        expect(flash[:success]).to eq(I18n.t("admin.answers.destroy.success"))
      end
      it "redirects to the question show page" do
        delete :destroy, params: { test_id: test.id, question_id: question.id, id: answer.id }
        expect(response).to redirect_to(admin_test_question_path(test, question))
      end
    end

    context "when destroy fails" do
      before do
        allow_any_instance_of(Answer).to receive(:destroy).and_return(false)
        delete :destroy, params: { test_id: test.id, question_id: question.id, id: answer.id }
      end
      it "sets an error flash message" do
        expect(flash[:error]).to eq(I18n.t("admin.answers.destroy.failure"))
      end
      it "redirects to the question show page" do
        expect(response).to redirect_to(admin_test_question_path(test, question))
      end
    end
  end

  # Test cho before_actions
  describe "before_actions" do
    context "when test is not found" do
      before { get :new, params: { test_id: -1, question_id: question.id } }

      it "redirects to admin tests path" do
        expect(response).to redirect_to(admin_tests_path)
      end
      it "sets an error flash message" do
        expect(flash[:error]).to eq(I18n.t("admin.answers.test_not_found"))
      end
    end

    context "when question is not found" do
      before { get :new, params: { test_id: test.id, question_id: -1 } }

      it "redirects to admin test path" do
        expect(response).to redirect_to(admin_test_path(test))
      end
      it "sets an error flash message" do
        expect(flash[:error]).to eq(I18n.t("admin.answers.question_not_found"))
      end
    end

    context "when answer is not found" do
      before { delete :destroy, params: { test_id: test.id, question_id: question.id, id: -1 } }

      it "redirects to admin test question path" do
        expect(response).to redirect_to(admin_test_question_path(test, question))
      end
      it "sets an error flash message" do
        expect(flash[:error]).to eq(I18n.t("admin.answers.answer_not_found"))
      end
    end
  end
end
