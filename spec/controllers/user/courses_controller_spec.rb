require "rails_helper"

RSpec.describe User::CoursesController, type: :controller do
  # --- Setup Dữ liệu ---
  let!(:user) { create(:user, :user) }
  let!(:course) { create(:course) }
  let!(:another_course) { create(:course) }

  # --- Test cho GET #index ---
  describe "GET #index" do
    let(:index_params) { { locale: :en } }

    context "as a guest" do
      before { get :index, params: index_params }

      it "returns a 200 OK status" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the 'index' template" do
        expect(response).to render_template(:index)
      end

      context "when status param is present" do
        before { get :index, params: index_params.merge(status: "enrolled") }

        it "redirects to courses index" do
          expect(response).to redirect_to(user_courses_path(locale: :en))
        end

        it "sets an alert flash" do
          expect(flash[:alert]).to be_present
        end
      end
    end

    context "as a logged-in user" do
      before do
        sign_in user
        get :index, params: index_params
      end

      it "returns a 200 OK status" do
        expect(response).to have_http_status(:ok)
      end

      it "assigns @courses" do
        expect(assigns(:courses)).to include(course, another_course)
      end
    end
  end

  # --- Test cho GET #show ---
  describe "GET #show" do
    let(:show_params) { { id: course.id, locale: :en } }

    context "as a logged-in user" do
      before { sign_in user }

      context "when user is enrolled and approved" do
        let!(:user_course) { create(:user_course, user: user, course: course, enrolment_status: :approved) }

        before { get :show, params: show_params }

        it "returns a 200 OK status" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the 'show' template" do
          expect(response).to render_template(:show)
        end

        it "assigns the correct @user_course" do
          expect(assigns(:user_course)).to eq(user_course)
        end
      end

      context "when user is not enrolled" do
        before { get :show, params: show_params }

        it "redirects to the courses index page" do
          expect(response).to redirect_to(user_courses_path(locale: :en))
        end

        it "sets a danger flash" do
          expect(flash[:danger]).to be_present
        end
      end

      context "when user enrolment is pending" do
        let!(:user_course) { create(:user_course, user: user, course: course, enrolment_status: :pending) }

        before { get :show, params: show_params }

        it "redirects to the courses index page" do
          expect(response).to redirect_to(user_courses_path(locale: :en))
        end

        it "sets a danger flash" do
          expect(flash[:danger]).to be_present
        end
      end
    end
  end

  # --- Test cho POST #enroll ---
  describe "POST #enroll" do
    let(:enroll_params) { { id: course.id, locale: :en } }

    context "as a logged-in user" do
      before { sign_in user }

      context "when not yet enrolled" do
        it "creates a new UserCourse" do
          expect {
            post :enroll, params: enroll_params
          }.to change(UserCourse, :count).by(1)
        end

        it "sets UserCourse status to pending" do
          post :enroll, params: enroll_params
          expect(UserCourse.last.pending?).to be true
        end

        context "after enroll" do
          before { post :enroll, params: enroll_params }

          it "redirects to the courses index" do
            expect(response).to redirect_to(user_courses_path(locale: :en))
          end

          it "sets a success flash" do
            expect(flash[:success]).to be_present
          end
        end

        context "when enrollment fails" do

          before do
            allow(UserCourse).to receive(:create).and_return(double(persisted?: false))
            post :enroll, params: { id: course.id, locale: :en }
          end

          it "redirects back to the courses index" do
            expect(response).to redirect_to(user_courses_path(locale: :en))
          end
        end
      end

      context "when already enrolled" do
        let!(:user_course) { create(:user_course, user: user, course: course) }

        it "does not create a new UserCourse" do
          expect {
            post :enroll, params: enroll_params
          }.not_to change(UserCourse, :count)
        end

        context "after enroll" do
          before { post :enroll, params: enroll_params }

          it "redirects to the courses index" do
            expect(response).to redirect_to(user_courses_path(locale: :en))
          end

          it "sets a warning flash" do
            expect(flash[:warning]).to be_present
          end
        end
      end
    end
  end

  # --- Test cho PATCH #start ---
  describe "PATCH #start" do
    let(:start_params) { { id: course.id, locale: :en } }

    context "as a logged-in user" do
      before { sign_in user }

      context "when enrolment is approved" do
        let!(:user_course) { create(:user_course, user: user, course: course, enrolment_status: :approved) }

        it "updates the UserCourse status to in_progress" do
          patch :start, params: start_params
          expect(user_course.reload.in_progress?).to be true
        end

        it "sets the start_date" do
          patch :start, params: start_params
          expect(user_course.reload.start_date).to eq(Date.current)
        end

        it "sets the end_date" do
          patch :start, params: start_params
          expect(user_course.reload.end_date).to eq(Date.current + course.duration.days)
        end

        context "after start" do
          before { patch :start, params: start_params }

          it "redirects to the course show page" do
            expect(response).to redirect_to(user_course_path(course, locale: :en))
          end

          it "sets a success flash" do
            expect(flash[:success]).to be_present
          end
        end
      end

      context "when enrolment is pending" do
        let!(:user_course) { create(:user_course, user: user, course: course, enrolment_status: :pending) }

        it "does not update the UserCourse status" do
          patch :start, params: start_params
          expect(user_course.reload.pending?).to be true
        end

        context "after start" do
          before { patch :start, params: start_params }

          it "redirects to the root" do
            expect(response).to redirect_to(root_path(locale: :en))
          end

          it "sets a danger flash" do
            expect(flash[:danger]).to be_present
          end
        end
      end

      context "when start fails" do
        let(:course) { create(:course) }
        let(:user_course) { create(:user_course, user: user, course: course, enrolment_status: :approved) }

        before do
          sign_in user
          allow_any_instance_of(UserCourse).to receive(:update).and_return(false)
          patch :start, params: { id: course.id, locale: :en }
        end

        it "sets a danger flash" do
          expect(flash[:danger]).to eq I18n.t("errors.messages.not_authorized")
        end

        it "redirects to root_path" do
          expect(response).to redirect_to(root_path(locale: :en))
        end
      end
    end
  end
end
