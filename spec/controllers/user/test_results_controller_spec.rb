require "rails_helper"

RSpec.describe User::TestResultsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:user)   { create(:user) }
  let!(:course) { create(:course) }
  let!(:lesson) { create(:lesson, course: course) }
  let!(:testrec){ create(:test, duration: 3) }

  let!(:component_test) { create(:component, :test, lesson: lesson, test: testrec) }

  let!(:q1) { create(:question, test: testrec, content: "Q1") }
  let!(:q2) { create(:question, test: testrec, content: "Q2") }
  let!(:a1) { create(:answer, question: q1, content: "A1") }
  let!(:a2) { create(:answer, question: q2, content: "A2") }

  let!(:test_result) do
    create(:test_result,
      user: user,
      component: component_test,
      user_answers: { q1.id.to_s => a1.id, q2.id.to_s => a2.id }
    )
  end

  let(:ability) do
    obj = Object.new
    obj.extend(CanCan::Ability)
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
    context "when test_result exists" do
      before do
        get :show, params: { course_id: course.id, lesson_id: lesson.id, id: test_result.id }
      end

      it "assigns @test_component from @test_result" do
        expect(assigns(:test_component)).to eq(component_test)
      end

      it "assigns @test from @test_component" do
        expect(assigns(:test)).to eq(testrec)
      end

      it "assigns @questions ordered by id" do
        expect(assigns(:questions)).to eq(testrec.questions.includes(:answers).order(:id))
      end

      it "assigns @total_questions equals questions count" do
        expect(assigns(:total_questions)).to eq(2)
      end

      it "assigns @user_answers_data from test_result" do
        expect(assigns(:user_answers_data)).to eq(test_result.user_answers)
      end
    end

    context "when test_result is not found" do
      before do
        get :show, params: { course_id: course.id, lesson_id: lesson.id, id: -1 }
      end

      it "sets flash danger with i18n message" do
        expect(flash[:danger]).to eq(I18n.t("user.test_results.show.error.test_result_not_found"))
      end

      it "redirects to user_course_lesson_path" do
        expect(response).to redirect_to(user_course_lesson_path(course, lesson))
      end
    end
  end
end
