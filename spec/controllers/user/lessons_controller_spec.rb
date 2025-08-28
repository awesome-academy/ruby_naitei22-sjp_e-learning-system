require "rails_helper"

RSpec.describe User::LessonsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:user)   { create(:user) }
  let!(:course) { create(:course) }
  let!(:lesson) { create(:lesson, course: course) }

  let!(:para1) { create(:component, :paragraph, lesson: lesson, index_in_lesson: 1, content: "P1") }
  let!(:para2) { create(:component, :paragraph, lesson: lesson, index_in_lesson: 3, content: "P2") }
  let!(:para3) { create(:component, :paragraph, lesson: lesson, index_in_lesson: 2, content: "P3") }

  let!(:word1) { create(:word, content: "alpha") }
  let!(:word2) { create(:word, content: "beta") }
  let!(:wc1)   { create(:component, :word, lesson: lesson, index_in_lesson: 4, word: word1) }
  let!(:wc2)   { create(:component, :word, lesson: lesson, index_in_lesson: 5, word: word2) }

  let!(:testrec) { create(:test, max_attempts: 3) }
  let!(:tc)      { create(:component, :test, lesson: lesson, test: testrec, index_in_lesson: 6) }
  let!(:q1)      { create(:question, test: testrec) }
  let!(:q2)      { create(:question, test: testrec) }
  let!(:tr1)     { create(:test_result, user: user, component: tc, attempt_number: 1) }
  let!(:tr2)     { create(:test_result, user: user, component: tc, attempt_number: 2) }

  let!(:user_lesson) { create(:user_lesson, user: user, lesson: lesson, status: 1, grade: 85) }

  let!(:enrolment) { create(:user_course, user: user, course: course, enrolment_status: :approved) }

  let(:ability) do
    obj = Object.new
    obj.extend(CanCan::Ability)
    obj.can :access, :user_area
    obj.can :read, Course
    obj.can :read, Lesson
    obj
  end

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in user
    allow(controller).to receive(:current_ability).and_return(ability)
  end

  describe "GET #show" do
    before { get :show, params: { course_id: course.id, id: lesson.id } }

    it "assigns @paragraphs ordered by index_in_lesson" do
      expect(assigns(:paragraphs).map(&:content)).to eq(%w[P1 P3 P2])
    end

    it "assigns @user_lesson for current_user and lesson" do
      expect(assigns(:user_lesson)).to eq(user_lesson)
    end

    it "assigns @lesson_test as the test component" do
      expect(assigns(:lesson_test)).to eq(tc)
    end

    it "assigns @number_of_attempts for current_user on lesson_test" do
      expect(assigns(:number_of_attempts)).to eq(2)
    end

    it "assigns @attempt_left as max_attempts - attempts" do
      expect(assigns(:attempt_left)).to eq(1) # 3 - 2
    end
  end

  describe "GET #study" do
    context "when lesson has words" do
      before { get :study, params: { course_id: course.id, id: lesson.id, word_index: 2 } }

      it "assigns @word_components sorted by index" do
        expect(assigns(:word_components).map { |c| c.word.content }).to eq(%w[alpha beta])
      end

      it "assigns @current_word based on word_index" do
        expect(assigns(:current_word)).to eq(word2)
      end

      it "assigns @current_position = index + 1" do
        expect(assigns(:current_position)).to eq(2)
      end

      it "assigns @has_previous correctly" do
        expect(assigns(:has_previous)).to be true
      end

      it "assigns @has_next correctly" do
        expect(assigns(:has_next)).to be false
      end
    end

    context "when lesson has NO words" do
      before do
        Component.where(lesson: lesson, component_type: :word).delete_all
        get :study, params: { course_id: course.id, id: lesson.id }
      end

      it "sets flash danger with i18n" do
        expect(flash[:danger]).to eq(I18n.t("user.lessons.study.error.no_words_found"))
      end

      it "redirects back to lesson page" do
        expect(response).to redirect_to(user_course_lesson_path(lesson.course, lesson))
      end
    end
  end

  describe "GET #test_history" do
    context "when test component exists" do
      before { get :test_history, params: { course_id: course.id, id: lesson.id } }

      it "assigns @test_results ordered by attempt_number" do
        expect(assigns(:test_results).map(&:attempt_number)).to eq([1, 2])
      end

      it "assigns @total_questions equals test.questions.count" do
        expect(assigns(:total_questions)).to eq(2)
      end

      it "assigns @lesson_status from user_lesson" do
        expect(assigns(:lesson_status)).to eq(user_lesson.status)
      end

      it "assigns @best_grade from user_lesson" do
        expect(assigns(:best_grade)).to eq(85)
      end

      it "assigns @number_of_attempts equals test_results.count" do
        expect(assigns(:number_of_attempts)).to eq(2)
      end
    end

    context "when test component does NOT exist" do
      before do
        Component.where(lesson: lesson, component_type: :test).delete_all
        get :test_history, params: { course_id: course.id, id: lesson.id }
      end

      it "sets flash danger with i18n" do
        expect(flash[:danger]).to eq(I18n.t("user.lessons.test_history.error.test_not_found"))
      end

      it "redirects to lesson page" do
        expect(response).to redirect_to(user_course_lesson_path(course, lesson))
      end
    end
  end
end
