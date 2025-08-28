require "rails_helper"

RSpec.describe Admin::UserCoursesController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin) { create(:user, role: :admin) }

  let(:ability) do
    obj = Object.new
    obj.extend(CanCan::Ability)
    obj.can :manage, UserCourse
    obj.can :manage, User
    obj.can :manage, Course
    obj
  end

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in admin
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(controller).to receive(:authorize_admin_area).and_return(true)
  end

  describe "GET #index" do
    let!(:course1) { create(:course, title: "Ruby 101") }
    let!(:course2) { create(:course, title: "Rails 7") }
    let!(:u1) { create(:user) }
    let!(:u2) { create(:user) }

    # tạo 25 bản ghi để có 2 trang
    let!(:ucs) do
      (1..25).map do |i|
        create(:user_course,
               user: i.odd? ? u1 : u2,
               course: i <= 12 ? course1 : course2,
               enrolment_status: :pending,
               created_at: i.minutes.ago)
      end
    end

    context "page=1 no filters" do
      before { get :index, params: { page: 1 } }

      it "responds with 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "assigns @pagy.count equals total filtered" do
        expect(assigns(:pagy).count).to eq(UserCourse.count)
      end

      it "assigns @user_courses size equals pagy.items" do
        expect(assigns(:user_courses).size).to eq(assigns(:pagy).items)
      end

      it "assigns recent order" do
        expected_ids = UserCourse.order(created_at: :desc)
                                 .limit(assigns(:pagy).items).pluck(:id)
        actual_ids = assigns(:user_courses).map(&:id)
        expect(actual_ids).to eq(expected_ids)
      end
    end

    context "page=2 with course/status filters" do
      before { get :index, params: { page: 2, course: course1.id, status: :pending } }

      it "filters by course and status" do
        ids = assigns(:user_courses).map(&:course_id).uniq
        expect(ids).to eq([course1.id])
      end
    end

    context "with registered_from & expiration_date filters" do
      before do
        from = 1.day.ago.to_date.to_s
        to   = 1.day.from_now.to_date.to_s
        get :index, params: { registered_from: from, expiration_date: to }
      end

      it "responds with 200 OK" do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH #approve" do
    let!(:user_course) { create(:user_course, enrolment_status: :pending) }

    context "when state changes to approved successfully" do
      before { patch :approve, params: { id: user_course.id, status: :pending, page: 2 } }

      it "sets flash success (i18n)" do
        expect(flash[:success]).to eq(I18n.t("admin.user_courses.approve.approve_success"))
      end

      it "redirects back to index preserving filters" do
        expect(response).to redirect_to(admin_user_courses_path(status: "pending", page: "2"))
      end
    end

    context "when approved! returns false" do
      before do
        allow_any_instance_of(UserCourse).to receive(:approved!).and_return(false)
        patch :approve, params: { id: user_course.id }
      end

      it "sets flash danger (i18n)" do
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.approve.approve_failed"))
      end
    end

    context "when exception is raised" do
      before do
        allow_any_instance_of(UserCourse).to receive(:approved!).and_raise(StandardError.new("boom"))
        patch :approve, params: { id: user_course.id }
      end

      it "sets flash danger (i18n) on error" do
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.approve.approve_failed"))
      end
    end
  end

  describe "GET #reject_form" do
    let!(:user_course) { create(:user_course) }

    it "invokes respond_modal_with with @user_course" do
      expect(controller).to receive(:respond_modal_with).with(user_course)
      get :reject_form, params: { id: user_course.id }
    end
  end

  describe "PATCH #reject" do
    let!(:user_course) { create(:user_course, enrolment_status: :pending) }

    context "when update! succeeds" do
      before { patch :reject, params: { id: user_course.id, reason: "Invalid docs", page: 3 } }

      it "sets enrolment_status to rejected" do
        expect(user_course.reload.rejected?).to be true
      end

      it "sets flash success (i18n)" do
        expect(flash[:success]).to eq(I18n.t("admin.user_courses.reject.reject_success"))
      end

      it "redirects back with preserved filters" do
        expect(response).to redirect_to(admin_user_courses_path(page: "3"))
      end
    end

    context "when update! raises error" do
      before do
        allow_any_instance_of(UserCourse).to receive(:update!).and_raise(StandardError.new("nope"))
        patch :reject, params: { id: user_course.id, reason: "x" }
      end

      it "sets flash danger (i18n)" do
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.reject.reject_failed"))
      end
    end
  end

  describe "POST #approve_selected" do
    let!(:c1) { create(:user_course, enrolment_status: :pending) }
    let!(:c2) { create(:user_course, enrolment_status: :pending) }
    let!(:c3) { create(:user_course, enrolment_status: :approved) }

    context "when no selection present" do
      it "redirects with flash danger no_selection" do
        post :approve_selected
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.approve_selected.no_selection"))
      end
    end

    context "when invalid courses exist" do
      before do
        ids = [c1.id, c3.id]
        allow(UserCourse).to receive_message_chain(:where, :approvable).and_return(UserCourse.where(id: [c1.id]))
        allow(UserCourse).to receive_message_chain(:where, :invalid_for_approve).and_return(UserCourse.where(id: [c3.id]))
        post :approve_selected, params: { user_course_ids: ids }
      end

      it "sets flash danger invalid_status_error" do
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.approve_selected.invalid_status_error"))
      end
    end

    context "when no approvable courses" do
      before do
        ids = [c3.id]
        allow(UserCourse).to receive_message_chain(:where, :approvable).and_return(UserCourse.none)
        allow(UserCourse).to receive_message_chain(:where, :invalid_for_approve).and_return(UserCourse.none)
        post :approve_selected, params: { user_course_ids: ids }
      end

      it "sets flash danger no_approvable_courses" do
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.approve_selected.no_approvable_courses"))
      end
    end

    context "when update selected to approved" do
      before do
        ids = [c1.id, c2.id]
        post :approve_selected, params: { user_course_ids: ids }
      end

      it "sets flash success with count" do
        expect(flash[:success]).to eq(I18n.t("admin.user_courses.approve_selected.approve_selected_success", count: 2))
      end
    end
  end

  describe "POST #reject_selected" do
    let!(:c1) { create(:user_course, enrolment_status: :pending) }
    let!(:c2) { create(:user_course, enrolment_status: :pending) }
    let!(:c3) { create(:user_course, enrolment_status: :approved) }

    context "when no selection present" do
      it "redirects with flash danger no_selection" do
        post :reject_selected
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.reject_selected.no_selection"))
      end
    end

    context "when invalid courses exist" do
      before do
        ids = [c1.id, c3.id]
        allow(UserCourse).to receive_message_chain(:where, :rejectable).and_return(UserCourse.where(id: [c1.id]))
        allow(UserCourse).to receive_message_chain(:where, :invalid_for_reject).and_return(UserCourse.where(id: [c3.id]))
        post :reject_selected, params: { user_course_ids: ids }
      end

      it "sets flash danger invalid_status_for_reject_error" do
        expect(flash[:danger]).to eq(I18n.t("admin.user_courses.reject_selected.invalid_status_for_reject_error"))
      end
    end

    context "when no rejectable courses" do
      before do
        ids = [c3.id]
        allow(UserCourse).to receive_message_chain(:where, :rejectable).and_return(UserCourse.none)
        allow(UserCourse).to receive_message_chain(:where, :invalid_for_reject).and_return(UserCourse.none)
        post :reject_selected, params: { user_course_ids: ids }
      end

      it "sets flash warning no_rejectable_courses" do
        expect(flash[:warning]).to eq(I18n.t("admin.user_courses.reject_selected.no_rejectable_courses"))
      end
    end

    context "when update selected to rejected" do
      before do
        ids = [c1.id, c2.id]
        post :reject_selected, params: { user_course_ids: ids }
      end

      it "sets flash success with count" do
        expect(flash[:success]).to eq(I18n.t("admin.user_courses.reject_selected.reject_selected_success", count: 2))
      end
    end
  end

  describe "GET #reject_detail" do
    let!(:user_course) { create(:user_course) }

    it "invokes respond_modal_with with @user_course" do
      expect(controller).to receive(:respond_modal_with).with(user_course)
      get :reject_detail, params: { id: user_course.id }
    end
  end

  describe "GET #profile" do
    let!(:user_course) { create(:user_course) }
    let!(:user) { user_course.user }
    let!(:course) { user_course.course }

    before do
      allow(course).to receive(:progress_percentage_for_user).with(user).and_return(42)
      allow(controller).to receive(:calculate_progress_percentage).and_call_original
      get :profile, params: { id: user_course.id }
    end

    it "assigns @user" do
      expect(assigns(:user)).to eq(user)
    end

    it "assigns @course" do
      expect(assigns(:course)).to eq(course)
    end

    it "assigns @progress_percentage from course" do
      expect(assigns(:progress_percentage)).to eq(42)
    end
  end
end
