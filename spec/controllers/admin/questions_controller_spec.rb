require "rails_helper"

RSpec.describe Admin::QuestionsController, type: :controller do
  let!(:admin_user) { create(:user, role: "admin") }
  let!(:test) { create(:test) }
  let!(:question) { create(:question, test: test) }

  def login_as_admin
    session[:user_id] = admin_user.id
  end

  before do
    login_as_admin
  end

  # Test cho GET #new
  describe "GET #new" do
    before do
      allow(Settings.question).to receive(:answer_defaults_number).and_return(2)
      get :new, params: { test_id: test.id }
    end

    it "assigns a new question to @question" do
      expect(assigns(:question)).to be_a_new(Question)
    end
    it "builds default answers for the question" do
      expect(assigns(:question).answers.size).to eq(2)
    end
    it "renders the new template" do
      expect(response).to render_template(:new)
    end
  end

  # Test cho POST #create
  describe "POST #create" do
    let(:valid_params) do
      { test_id: test.id, question: {
          content: "New question", question_type: :single_choice,
          answers_attributes: [{ content: "Correct", correct: true }, { content: "Incorrect", correct: false }]
        }
      }
    end

    context "with valid params" do
      it "creates a new question" do
        expect { post :create, params: valid_params }.to change(Question, :count).by(1)
      end
      it "redirects to the test show page" do
        post :create, params: valid_params
        expect(response).to redirect_to(admin_test_path(test))
      end
      it "sets a success flash message" do
        post :create, params: valid_params
        expect(flash[:success]).to eq(I18n.t("admin.questions.create.success"))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        { test_id: test.id, question: { content: nil } }
      end

      it "does not create a new question" do
        expect { post :create, params: invalid_params }.not_to change(Question, :count)
      end
      it "renders the new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
      it "sets a danger flash message" do
        post :create, params: invalid_params
        expect(flash[:danger]).to eq(I18n.t("admin.questions.create.failure"))
      end
    end
  end

  # Test cho GET #edit
  describe "GET #edit" do
    it "renders the edit template" do
      get :edit, params: { test_id: test.id, id: question.id }
      expect(response).to render_template(:edit)
    end
  end

  # Test cho PATCH #update
  describe "PATCH #update" do
    let(:new_content) { "Updated content" }
    let(:valid_update_params) do
      { test_id: test.id, id: question.id,
        question: { content: new_content }
      }
    end

    context "with valid params" do
      it "updates the question" do
        patch :update, params: valid_update_params
        question.reload
        expect(question.content).to eq(new_content)
      end
      it "redirects to the test show page" do
        patch :update, params: valid_update_params
        expect(response).to redirect_to(admin_test_path(test))
      end
      it "sets a success flash message" do
        patch :update, params: valid_update_params
        expect(flash[:success]).to eq(I18n.t("admin.questions.update.success"))
      end
    end

    context "with invalid params" do
      let(:invalid_update_params) do
        { test_id: test.id, id: question.id,
          question: { content: nil }
        }
      end

      it "does not update the question" do
        patch :update, params: invalid_update_params
        question.reload
        expect(question.content).not_to be_nil
      end
      it "renders the edit template" do
        patch :update, params: invalid_update_params
        expect(response).to render_template(:edit)
      end
      it "sets a danger flash message" do
        patch :update, params: invalid_update_params
        expect(flash[:danger]).to eq(I18n.t("admin.questions.update.failure"))
      end
    end
  end

  # Test cho DELETE #destroy
  describe "DELETE #destroy" do
    it "destroys the requested question" do
      expect { delete :destroy, params: { test_id: test.id, id: question.id } }.to change(Question, :count).by(-1)
    end
    it "redirects to the test show page" do
      delete :destroy, params: { test_id: test.id, id: question.id }
      expect(response).to redirect_to(admin_test_path(test))
    end
    it "sets a success flash message" do
      delete :destroy, params: { test_id: test.id, id: question.id }
      expect(flash[:success]).to eq(I18n.t("admin.questions.destroy.success"))
    end

    context "when destroy fails" do
      before do
        allow_any_instance_of(Question).to receive(:destroy).and_return(false)
        delete :destroy, params: { test_id: test.id, id: question.id }
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.questions.destroy.failure"))
      end
    end
  end

  # Test cho before_actions
  describe "before_actions" do
    context "when test is not found" do
      before { get :new, params: { test_id: -1 } }

      it "redirects to admin tests path" do
        expect(response).to redirect_to(admin_tests_path)
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.questions.test_not_found"))
      end
    end

    context "when question is not found" do
      before { get :edit, params: { test_id: test.id, id: -1 } }

      it "redirects to admin test path" do
        expect(response).to redirect_to(admin_test_path(test))
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.questions.question_not_found"))
      end
    end
  end
end
