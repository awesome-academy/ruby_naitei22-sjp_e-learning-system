require "rails_helper"

RSpec.describe User::LessonsController, type: :controller do
  let!(:user) { create(:user) }
  let!(:course) { create(:course) }
  let!(:lesson) { create(:lesson, course: course) }

  def login_as_user
    session[:user_id] = user.id
  end

  before do
    login_as_user
  end

  # Test cho GET #show
  describe "GET #show" do
    let!(:paragraph_component) { create(:paragraph_component, lesson: lesson, index_in_lesson: 1) }
    let!(:test_component) { create(:test_component, lesson: lesson, test: create(:test)) }
    let!(:user_lesson) { create(:user_lesson, user: user, lesson: lesson) }
    let!(:test_result) { create(:test_result, user: user, component: test_component) }

    before { get :show, params: { course_id: course.id, id: lesson.id } }

    it "assigns paragraphs to @paragraphs" do
      expect(assigns(:paragraphs)).to eq([paragraph_component])
    end
    it "assigns user_lesson to @user_lesson" do
      expect(assigns(:user_lesson)).to eq(user_lesson)
    end
    it "assigns lesson test to @lesson_test" do
      expect(assigns(:lesson_test)).to eq(test_component)
    end
    it "assigns number of attempts to @number_of_attempts" do
      expect(assigns(:number_of_attempts)).to eq(1)
    end
    it "assigns attempt left to @attempt_left" do
      expect(assigns(:attempt_left)).to eq(test_component.test.max_attempts - 1)
    end
    it "renders the show template" do
      expect(response).to render_template(:show)
    end
  end

  # Test cho GET #study
  describe "GET #study" do
    let!(:word_component1) { create(:word_component, lesson: lesson, word: create(:word), index_in_lesson: 1) }
    let!(:word_component2) { create(:word_component, lesson: lesson, word: create(:word), index_in_lesson: 2) }

    context "when a valid word_index is completeded" do
      before { get :study, params: { course_id: course.id, id: lesson.id, word_index: 2 } }

      it "assigns the course to @course" do
        expect(assigns(:course)).to eq(course)
      end
      it "assigns word components to @word_components" do
        expect(assigns(:word_components)).to match_array([word_component1, word_component2])
      end
    end

    context "when word_index is 0" do
      it "assigns correct word data" do
        get :study, params: { course_id: course.id, id: lesson.id, word_index: 0 }
        expect(assigns(:has_previous)).to be_falsey
        expect(assigns(:previous_index)).to be_nil
      end
    end

    context "when word components are empty" do
      before { allow_any_instance_of(Lesson).to receive_message_chain(:components, :word, :exists?).and_return(false) }
      it "redirects with an error message" do
        get :study, params: { course_id: course.id, id: lesson.id }
        expect(response).to redirect_to(user_course_lesson_path(course, lesson))
        expect(flash[:danger]).to eq(I18n.t("user.lessons.study.error.no_words_found"))
      end
    end
  end

  # Test cho GET #test_history
  describe "GET #test_history" do
    let!(:test_component) { create(:test_component, lesson: lesson, test: create(:test)) }
    let!(:question1) { create(:question, test: test_component.test) }
    let!(:test_result1) { create(:test_result, user: user, component: test_component, attempt_number: 1, submitted: true) }
    let!(:test_result2) { create(:test_result, user: user, component: test_component, attempt_number: 2, submitted: true) }
    let!(:user_lesson) { create(:user_lesson, user: user, lesson: lesson, status: :completed, grade: 90) }

    before { get :test_history, params: { course_id: course.id, id: lesson.id } }

    it "assigns test results to @test_results" do
      expect(assigns(:test_results)).to eq([test_result1, test_result2])
    end
    it "assigns total questions count to @total_questions" do
      expect(assigns(:total_questions)).to eq(1)
    end
    it "assigns lesson status to @lesson_status" do
      expect(assigns(:lesson_status)).to eq("completed")
    end
    it "assigns best grade to @best_grade" do
      expect(assigns(:best_grade)).to eq(90)
    end
    it "assigns number of attempts to @number_of_attempts" do
      expect(assigns(:number_of_attempts)).to eq(2)
    end
    it "renders the test_history template" do
      expect(response).to render_template(:test_history)
    end
  end

  # Test cho private methods (before_actions)
  describe "before_actions" do
    context "when course is not found" do
      before { get :show, params: { course_id: -1, id: lesson.id } }
      it "redirects to root path" do
        expect(response).to redirect_to(root_path)
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("user.lessons.show.error.course_not_found"))
      end
    end

    context "when lesson is not found" do
      before { get :show, params: { course_id: course.id, id: -1 } }
      it "redirects to user course path" do
        expect(response).to redirect_to(user_course_path(course))
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("user.lessons.show.error.lesson_not_found"))
      end
    end
  end
end
