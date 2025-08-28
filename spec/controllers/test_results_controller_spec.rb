require "rails_helper"

RSpec.describe User::TestResultsController, type: :controller do

  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  let(:admin_user) { create(:user, :admin) }
  let(:normal_user) { create(:user, :user) }
  let(:another_user) { create(:user, :user) }
  let(:user) { create(:user, :user) }

  let!(:test_object) { create(:test) }

  let!(:course) { create(:course) }
  let!(:lesson) { create(:lesson, course: course) }
  let!(:test_result) { create(:test_result, user: normal_user, component: create(:component, lesson: lesson)) }
  let!(:another_test_result) { create(:test_result, user: another_user, component: create(:component, lesson: lesson)) }
  describe "GET #show" do
    context "when a user with 'admin' role is logged in" do
      before do
        sign_in admin_user
        get :show, params: { course_id: course.id, lesson_id: lesson.id, id: test_result.id }
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path(locale: :vi)) # Nhớ thêm locale nếu cần
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to be_present
      end
    end

    context "when a guest is accessing" do
      before do
        get :show, params: { course_id: course.id, lesson_id: lesson.id, id: test_result.id }
      end

      it "redirects to the login page" do
        expect(response).to redirect_to(new_user_session_path(locale: nil)) # Nhớ thêm locale
      end
    end

    context "when user tries to view another user's result" do
      before do
        sign_in user

        get :show, params: { course_id: course.id, lesson_id: lesson.id, id: another_test_result.id }
      end

      it "redirects to the home page" do
        expect(response).to redirect_to(root_path)
      end

      it "displays an error message" do
        expect(flash[:danger]).to be_present
      end
    end

    context "when user is not logged in" do
      before do
        get :show, params: { course_id: course.id, lesson_id: lesson.id, id: test_result.id }
      end

      it "redirects to the login page" do
        expect(response).to redirect_to(new_user_session_path(locale: nil))
      end
    end

    context "when test result does not exist" do
      before do
        sign_in user
        get :show, params: { course_id: course.id, lesson_id: lesson.id, id: -1 }
      end

      it "redirects to the root page" do
        expect(response).to redirect_to(root_path)
      end

      it "displays an error message" do
        expect(flash[:danger]).to be_present
      end
    end

    context "when lesson does not exist" do
      before do
        sign_in user
        get :show, params: { course_id: course.id, lesson_id: -1, id: test_result.id }
      end

      it "redirects to the home page" do
        expect(response).to redirect_to(root_path)
      end

      it "displays an error message" do
        expect(flash[:danger]).to be_present
      end
    end

    context "when course does not exist" do
      before do
        sign_in user
        get :show, params: { course_id: -1, lesson_id: lesson.id, id: test_result.id }
      end

      it "redirects to the home page" do
        expect(response).to redirect_to(root_path)
      end

      it "displays an error message" do
        expect(flash[:danger]).to be_present
      end
    end
  end
end
