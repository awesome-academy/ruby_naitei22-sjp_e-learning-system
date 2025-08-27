require "rails_helper"

RSpec.describe User::CoursesController, type: :controller do
  let!(:user) { create(:user) }
  let!(:course1) { create(:course, title: "Course A", created_at: 2.days.ago) }
  let!(:course2) { create(:course, title: "Course B", created_at: 1.day.ago) }

  def login_as_user
    session[:user_id] = user.id
  end

  before do
    login_as_user
    allow(Settings).to receive(:page_6).and_return(6)
  end

  # Test cho GET #index
  describe "GET #index" do
    before { get :index }

    it "assigns courses to @courses" do
      expect(assigns(:courses)).to match_array([course1, course2])
    end
    it "assigns user courses map to @user_courses_map" do
      expect(assigns(:user_courses_map)).to be_a(Hash)
    end
    it "renders the index template" do
      expect(response).to render_template(:index)
    end
  end

  # Test cho GET #show
  describe "GET #show" do
    let!(:user_course) { create(:user_course, user: user, course: course1, enrolment_status: :approved) }
    let!(:lesson1) { create(:lesson, course: course1, position: 1) }
    let!(:lesson2) { create(:lesson, course: course1, position: 2) }

    before { get :show, params: { id: course1.id } }

    it "assigns the course to @course" do
      expect(assigns(:course)).to eq(course1)
    end
    it "assigns the user course to @user_course" do
      expect(assigns(:user_course)).to eq(user_course)
    end
    it "assigns the lessons to @lessons" do
      expect(assigns(:lessons)).to eq([lesson1, lesson2])
    end
    it "assigns progress data" do
      expect(assigns(:total_lessons)).to eq(2)
      expect(assigns(:completed_count)).to eq(0)
    end
  end

  # Test cho POST #enroll
  describe "POST #enroll" do
    context "when enrollment is successful" do
      it "creates a new user course" do
        expect { post :enroll, params: { id: course1.id } }.to change(UserCourse, :count).by(1)
      end
      it "sets a success flash message" do
        post :enroll, params: { id: course1.id }
        expect(flash[:success]).to eq(I18n.t("user.courses.enroll.success_enrolled"))
      end
      it "redirects to the courses index" do
        post :enroll, params: { id: course1.id }
        expect(response).to redirect_to(user_courses_path)
      end
    end

    context "when enrollment fails" do
      before do
        allow_any_instance_of(UserCourse).to receive(:save).and_return(false)
        post :enroll, params: { id: course1.id }
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("user.courses.enroll.failed_enroll"))
      end
      it "redirects to the courses index" do
        expect(response).to redirect_to(user_courses_path)
      end
    end
  end

  # Test cho PATCH #start
  describe "PATCH #start" do
    let!(:user_course) { create(:user_course, user: user, course: course1, enrolment_status: :approved) }

    context "when course progress updates successfully" do
      before do
        allow_any_instance_of(UserCourse).to receive(:update).and_return(true)
        patch :start, params: { id: course1.id }
      end
      it "sets a success flash message" do
        expect(flash[:success]).to eq(I18n.t("user.courses.start.success"))
      end
      it "redirects to the course show page" do
        expect(response).to redirect_to(user_course_path(course1))
      end
    end

    context "when course progress update fails" do
      before do
        allow_any_instance_of(UserCourse).to receive(:update).and_return(false)
        patch :start, params: { id: course1.id }
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("user.courses.start.failed"))
      end
      it "redirects to the courses index" do
        expect(response).to redirect_to(user_courses_path)
      end
    end
  end

  # Test cho private methods (before_actions)
  describe "before_actions" do
    context "when a guest with status param attempts to access index" do
      it "redirects guest user to login page" do
        session[:user_id] = nil
        get :index, params: { status: "pending" }
        expect(response).to redirect_to(user_courses_path)
        expect(flash[:alert]).to eq(I18n.t("flash.please_log_in"))
      end
    end

    context "when a user is already enrolled" do
      let!(:user_course) { create(:user_course, user: user, course: course1, enrolment_status: :pending) }
      it "redirects with a warning flash message" do
        post :enroll, params: { id: course1.id }
        expect(response).to redirect_to(user_courses_path)
        expect(flash[:warning]).to eq(I18n.t("user.courses.enroll.already_enrolled"))
      end
    end

    context "when a course is not found" do
      it "redirects with a danger flash message" do
        get :show, params: { id: -1 }
        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq(I18n.t("user.courses.enroll.course_not_found"))
      end
    end

    context "when user course is not found or is pending" do
      let!(:pending_user_course) { create(:user_course, user: user, course: course1, enrolment_status: :pending) }
      it "redirects with a danger flash message" do
        get :show, params: { id: course1.id }
        expect(response).to redirect_to(user_courses_path)
        expect(flash[:danger]).to eq(I18n.t("user.courses.show.error.not_enrolled"))
      end
    end
  end
end
