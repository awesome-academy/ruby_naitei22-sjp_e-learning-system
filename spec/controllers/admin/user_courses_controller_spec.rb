require "rails_helper"

RSpec.describe Admin::UserCoursesController, type: :controller do
  let(:admin) { create(:user, :admin) }
  let(:course) { create(:course) }
  let(:user)   { create(:user) }
  let!(:user_course) { create(:user_course, user: user, course: course, enrolment_status: :pending) }

  before { sign_in admin }

  describe "GET #index" do
    before { get :index, params: { locale: :en } }

    it { expect(assigns(:user_courses)).to be_present }
    it { expect(assigns(:courses)).to include(course) }
    it { expect(response).to render_template(:index) }
  end

  describe "PATCH #approve" do
    context "when approve succeeds" do
      before do
        allow_any_instance_of(UserCourse).to receive(:approved!).and_return(true)
        patch :approve, params: { id: user_course.id, locale: :en }
      end

      it { expect(flash[:success]).to be_present }
    end

    context "when approve fails" do
      before do
        allow_any_instance_of(UserCourse).to receive(:approved!).and_return(false)
        patch :approve, params: { id: user_course.id, locale: :en }
      end

      it { expect(flash[:danger]).to be_present }
    end

    context "when exception raised" do
      before do
        allow_any_instance_of(UserCourse).to receive(:approved!).and_raise(StandardError, "boom")
        patch :approve, params: { id: user_course.id, locale: :en }
      end

      it { expect(flash[:danger]).to be_present }
    end
  end

  describe "GET #reject_form" do
    before { get :reject_form, params: { id: user_course.id, locale: :en } }
    it { expect(response).to be_successful }
  end

  describe "PATCH #reject" do
    context "success" do
      before { patch :reject, params: { id: user_course.id, reason: "spam", locale: :en } }
      it { expect(flash[:success]).to be_present }
    end

    context "failure" do
      before do
        allow_any_instance_of(UserCourse).to receive(:update!).and_raise(StandardError)
        patch :reject, params: { id: user_course.id, reason: "spam", locale: :en }
      end
      it { expect(flash[:danger]).to be_present }
    end
  end

  describe "POST #approve_selected" do
    let!(:uc1) { create(:user_course, enrolment_status: :pending) }

    context "when invalid exists" do
      before do
        selected_relation = UserCourse.where(id: uc1.id)
        allow(UserCourse).to receive(:where).and_return(selected_relation)
        allow(selected_relation).to receive(:approvable).and_return(UserCourse.none)
        allow(selected_relation).to receive(:invalid_for_approve).and_return(selected_relation)

        post :approve_selected, params: { user_course_ids: [uc1.id], locale: :en }
      end

      it { expect(flash[:danger]).to be_present }
    end

    context "when no approvable" do
      before do
        allow(UserCourse).to receive_message_chain(:where, :approvable).and_return(UserCourse.none)
        allow(UserCourse).to receive_message_chain(:where, :invalid_for_approve).and_return(UserCourse.none)
        post :approve_selected, params: { user_course_ids: [uc1.id], locale: :en }
      end
      it { expect(flash[:danger]).to be_present }
    end

    context "when some approvable" do
      before do
        allow(UserCourse).to receive_message_chain(:where, :approvable).and_return(UserCourse.where(id: uc1.id))
        allow(UserCourse).to receive_message_chain(:where, :invalid_for_approve).and_return(UserCourse.none)
        post :approve_selected, params: { user_course_ids: [uc1.id], locale: :en }
      end
      it { expect(flash[:success]).to be_present }
    end
  end

  describe "POST #reject_selected" do
    let!(:uc1) { create(:user_course, enrolment_status: :pending) }

    context "when invalid exists" do
    before do
      selected_relation = UserCourse.where(id: uc1.id)

      allow(UserCourse).to receive(:where).and_return(selected_relation)
      allow(selected_relation).to receive(:rejectable).and_return(UserCourse.none)
      allow(selected_relation).to receive(:invalid_for_reject).and_return(selected_relation)

      post :reject_selected, params: { user_course_ids: [uc1.id], locale: :en }
    end

    it { expect(flash[:danger]).to be_present }
  end

    context "when no rejectable" do
      before do
        allow(UserCourse).to receive_message_chain(:where, :rejectable).and_return(UserCourse.none)
        allow(UserCourse).to receive_message_chain(:where, :invalid_for_reject).and_return(UserCourse.none)
        post :reject_selected, params: { user_course_ids: [uc1.id], locale: :en }
      end
      it { expect(flash[:warning]).to be_present }
    end

    context "when some rejectable" do
      before do
        allow(UserCourse).to receive_message_chain(:where, :rejectable).and_return(UserCourse.where(id: uc1.id))
        allow(UserCourse).to receive_message_chain(:where, :invalid_for_reject).and_return(UserCourse.none)
        post :reject_selected, params: { user_course_ids: [uc1.id], locale: :en }
      end
      it { expect(flash[:success]).to be_present }
    end
  end

  describe "GET #reject_detail" do
    before { get :reject_detail, params: { id: user_course.id, locale: :en } }
    it { expect(response).to be_successful }
  end

  describe "GET #profile" do
    before do
      allow_any_instance_of(Course).to receive(:progress_percentage_for_user).and_return(50)
      get :profile, params: { id: user_course.id, locale: :en }
    end
    it { expect(assigns(:progress_percentage)).to eq 50 }
  end

  describe "private methods coverage" do
    controller do
      def index
        render plain: preserved_filters.to_json
      end
    end

    it "returns filters from params" do
      get :index, params: { course: 1, locale: :en }
      expect(response.body).to include("course")
    end

    it "returns filters from referer" do
      request.env["HTTP_REFERER"] = "/admin/user_courses?status=pending"
      get :index, params: { locale: :en }
      expect(response.body).to include("pending")
    end

    it "returns empty filters when no referer" do
      get :index, params: { locale: :en }
      expect(response.body).to eq("{}")
    end
  end

  describe "set_user_course" do
    it "redirects when not found" do
      get :reject_form, params: { id: 99999, locale: :en }
      expect(response).to redirect_to(admin_user_courses_path)
    end
  end

  describe "ensure_selection_present" do
    it "redirects when no selection" do
      post :approve_selected, params: { locale: :en }
      expect(response).to redirect_to(admin_user_courses_path)
    end
  end
end
