require "rails_helper"

RSpec.describe User::TestResultsController, type: :controller do
  let!(:user) { create(:user) }
  let!(:another_user) { create(:user) }
  let!(:course) { create(:course) }
  let!(:lesson) { create(:lesson, course: course) }
  let!(:test) { create(:test) }
  let!(:question) { create(:question, test: test) }
  let!(:answer) { create(:answer, question: question) }
  let!(:test_component) { create(:test_component, lesson: lesson, test: test) }
  let!(:test_result) do
    create(:test_result, user: user, component: test_component, submitted: true,
                         user_answers: { "1" => { "question_id" => "1", "selected_answer_ids" => ["1"] } })
  end

  def login_as_user
    session[:user_id] = user.id
  end

  before do
    login_as_user
  end

  describe "GET #show" do
    context "when a valid test result exists" do
      before { get :show, params: { course_id: course.id, lesson_id: lesson.id, id: test_result.id } }

      it "assigns the test result to @test_result" do
        expect(assigns(:test_result)).to eq(test_result)
      end
      it "assigns the test component to @test_component" do
        expect(assigns(:test_component)).to eq(test_component)
      end
      it "assigns the test to @test" do
        expect(assigns(:test)).to eq(test)
      end
      it "assigns questions to @questions" do
        expect(assigns(:questions)).to eq([question])
      end
      it "assigns the total number of questions to @total_questions" do
        expect(assigns(:total_questions)).to eq(1)
      end
      it "assigns user answers to @user_answers_data" do
        expect(assigns(:user_answers_data)).to eq(test_result.user_answers)
      end
      it "renders the show template" do
        expect(response).to render_template(:show)
      end
    end
  end

  describe "before_actions" do
    context "when course or lesson is not found" do
      it "redirects to root path when course is not found" do
        get :show, params: { course_id: -1, lesson_id: lesson.id, id: test_result.id }
        expect(response).to redirect_to(root_path)
      end
      it "sets a danger flash message when course is not found" do
        get :show, params: { course_id: -1, lesson_id: lesson.id, id: test_result.id }
        expect(flash[:danger]).to eq(I18n.t("user.test_results.error.course_or_lesson_not_found"))
      end
      it "redirects to root path when lesson is not found" do
        get :show, params: { course_id: course.id, lesson_id: -1, id: test_result.id }
        expect(response).to redirect_to(root_path)
      end
      it "sets a danger flash message when lesson is not found" do
        get :show, params: { course_id: course.id, lesson_id: -1, id: test_result.id }
        expect(flash[:danger]).to eq(I18n.t("user.test_results.error.course_or_lesson_not_found"))
      end
    end

    context "when test result is not found" do
      it "redirects to the lesson show path" do
        get :show, params: { course_id: course.id, lesson_id: lesson.id, id: -1 }
        expect(response).to redirect_to(user_course_lesson_path(course, lesson))
      end
      it "sets a danger flash message" do
        get :show, params: { course_id: course.id, lesson_id: lesson.id, id: -1 }
        expect(flash[:danger]).to eq(I18n.t("user.test_results.error.test_result_not_found"))
      end
    end

    context "when authorization fails" do
      before do
        session[:user_id] = another_user.id
      end
      it "redirects to root path" do
        get :show, params: { course_id: course.id, lesson_id: lesson.id, id: test_result.id }
        expect(response).to redirect_to(root_path)
      end
      it "sets a danger flash message" do
        get :show, params: { course_id: course.id, lesson_id: lesson.id, id: test_result.id }
        expect(flash[:danger]).to eq(I18n.t("user.test_results.error.unauthorized_access"))
      end
    end
  end
end
