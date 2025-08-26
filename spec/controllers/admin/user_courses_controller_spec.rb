require "rails_helper"

RSpec.describe Admin::UserCoursesController, type: :controller do
  let!(:admin_user) { create(:user, role: "admin") }
  let!(:user) { create(:user) }
  let!(:course1) { create(:course, title: "Course A") }
  let!(:course2) { create(:course, title: "Course B") }
  let!(:user_course1) { create(:user_course, user: user, course: course1, enrolment_status: :pending) }
  let!(:user_course2) { create(:user_course, user: user, course: course2, enrolment_status: :pending) }

  def login_as_admin
    session[:user_id] = admin_user.id
  end

  before do
    login_as_admin
    allow(Settings.user_course).to receive(:pagy_items).and_return(10)
  end

  # Test cho GET #index
  describe "GET #index" do
    before { get :index }

    it "assigns user courses to @user_courses" do
      expect(assigns(:user_courses)).to match_array([user_course1, user_course2])
    end

    it "assigns all courses to @courses" do
      expect(assigns(:courses)).to match_array([course1, course2])
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end
  end

  # Test cho PATCH #approve
  describe "PATCH #approve" do
    context "when approval is successful" do
      it "updates the user course status" do
        patch :approve, params: { id: user_course1.id }
        user_course1.reload
        expect(user_course1.enrolment_status).to eq("approved")
      end

      it "sets a success flash message" do
        patch :approve, params: { id: user_course1.id }
        expect(flash[:success]).to eq(I18n.t("admin.user_courses.approve.approve_success"))
      end

      it "redirects to the index page with filters" do
        patch :approve, params: { id: user_course1.id }
        expect(response).to redirect_to(admin_user_courses_path)
      end
    end

    context "when approval fails" do
      before do
        allow_any_instance_of(UserCourse).to receive(:approved!).and_return(false)
        patch :approve, params: { id: user_course1.id }
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.approve.approve_failed"))
      end

      it "redirects to the index page with filters" do
        expect(response).to redirect_to(admin_user_courses_path)
      end
    end
  end

  # Test cho GET #reject_form
  describe "GET #reject_form" do
    before { get :reject_form, params: { id: user_course1.id } }

    it "assigns the user course to @user_course" do
      expect(assigns(:user_course)).to eq(user_course1)
    end

    it "responds with modal" do
      expect(response).to be_successful
    end
  end

  # Test cho PATCH #reject
  describe "PATCH #reject" do
    context "when rejection is successful" do
      it "updates the user course status" do
        patch :reject, params: { id: user_course1.id, reason: "Not suitable" }
        user_course1.reload
        expect(user_course1.enrolment_status).to eq("rejected")
      end

      it "updates the user course reason" do
        patch :reject, params: { id: user_course1.id, reason: "Not suitable" }
        user_course1.reload
        expect(user_course1.reason).to eq("Not suitable")
      end

      it "sets a success flash message" do
        patch :reject, params: { id: user_course1.id, reason: "Not suitable" }
        expect(flash[:success]).to eq(I18n.t("admin.user_courses.reject.reject_success"))
      end

      it "redirects to the index page with filters" do
        patch :reject, params: { id: user_course1.id }
        expect(response).to redirect_to(admin_user_courses_path)
      end
    end

    context "when rejection fails" do
      before do
        allow_any_instance_of(UserCourse).to receive(:update!).and_raise(StandardError)
        patch :reject, params: { id: user_course1.id }
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.reject.reject_failed"))
      end

      it "redirects to the index page with filters" do
        expect(response).to redirect_to(admin_user_courses_path)
      end
    end
  end

  # Test cho POST #approve_selected
  describe "POST #approve_selected" do
    let!(:user_course3) { create(:user_course, user: user, course: course2, enrolment_status: :approved) }

    context "when there are invalid courses" do
      it "sets a danger flash message" do
        post :approve_selected, params: { user_course_ids: [user_course1.id, user_course3.id] }
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.approve_selected.invalid_status_error"))
      end
    end

    context "when there are no approvable courses" do
      it "sets a danger flash message" do
        post :approve_selected, params: { user_course_ids: [user_course3.id] }
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.approve_selected.invalid_status_error"))
      end
    end

    context "when selection is valid" do
      it "approves the selected courses" do
        post :approve_selected, params: { user_course_ids: [user_course1.id] }
        expect(user_course1.reload.enrolment_status).to eq("approved")
      end
    end
  end

  # Test cho POST #reject_selected
  describe "POST #reject_selected" do
    let!(:user_course3) { create(:user_course, user: user, course: course2, enrolment_status: :rejected, reason: "Inappropriate content") }

    context "when selection is valid" do
      it "rejects the selected courses" do
        post :reject_selected, params: { user_course_ids: [user_course1.id] }
        expect(user_course1.reload.enrolment_status).to eq("rejected")
      end
    end
  end

  # Test cho GET #reject_detail
  describe "GET #reject_detail" do
    before { get :reject_detail, params: { id: user_course1.id } }

    it "assigns the user course to @user_course" do
      expect(assigns(:user_course)).to eq(user_course1)
    end
    it "responds with modal" do
      expect(response).to be_successful
    end
  end

  # Test cho private methods (before_actions)
  describe "before_actions" do
    context "when a user course is not found" do
      before { get :reject_form, params: { id: -1 } }

      it "redirects to the user courses index" do
        expect(response).to redirect_to(admin_user_courses_path)
      end
    end

    context "when no selection is present" do
      before { post :approve_selected, params: { user_course_ids: nil } }

      it "redirects to the user courses index" do
        expect(response).to redirect_to(admin_user_courses_path)
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.approve_selected.no_selection"))
      end
    end
  end
end
