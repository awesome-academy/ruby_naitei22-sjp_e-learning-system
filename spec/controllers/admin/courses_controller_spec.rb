require "rails_helper"

RSpec.describe Admin::CoursesController, type: :controller do
  let!(:admin_user) { create(:user, role: "admin") }
  let!(:regular_user) { create(:user) }
  let!(:course1) { create(:course, title: "Course A", creator: admin_user, created_at: 2.days.ago) }
  let!(:course2) { create(:course, title: "Course B", creator: admin_user, created_at: 1.day.ago) }

  def login_as_admin
    session[:user_id] = admin_user.id
  end

  before do
    login_as_admin
    allow(Settings.course).to receive(:page_number).and_return(10)
  end

  # Test cho GET #index
  describe "GET #index" do
    before { get :index }

    it "assigns all courses ordered by recent to @courses" do
      expect(assigns(:courses)).to eq([course2, course1])
    end
    it "renders the index template" do
      expect(response).to render_template(:index)
    end
  end

  # Test cho GET #show
  describe "GET #show" do
    let!(:lesson1) { create(:lesson, course: course1) }
    before { get :show, params: { id: course1.id } }

    it "assigns the requested course to @course" do
      expect(assigns(:course)).to eq(course1)
    end
    it "renders the show template" do
      expect(response).to render_template(:show)
    end
  end

  # Test cho GET #new
  describe "GET #new" do
    before { get :new }

    it "assigns a new course to @course" do
      expect(assigns(:course)).to be_a_new(Course)
    end
    it "assigns admin users to @admin_users" do
      expect(assigns(:admin_users)).to include(admin_user)
    end
    it "renders the new template" do
      expect(response).to render_template(:new)
    end
  end

  # Test cho POST #create
  describe "POST #create" do
    let!(:creator_user) { create(:user) }
    let!(:admin_user) { create(:admin_user) }

    context "with valid params" do
      let(:valid_params) do
        {
          course: {
            title: "New Course Title",
            description: "A description for the new course.",
            duration: 100,
            created_by_id: admin_user.id
          }
        }
      end

      it "creates a new course" do
        expect { post :create, params: valid_params }.to change(Course, :count).by(1)
      end

      it "sets a success flash message" do
        post :create, params: valid_params
        expect(flash[:success]).to eq(I18n.t("admin.courses.create_success"))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          course: {
            title: nil,
            description: "This is an invalid course description."
          }
        }
      end

      it "does not create a new course" do
        expect { post :create, params: invalid_params }.not_to change(Course, :count)
      end

      it "renders the new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  # Test cho GET #edit
  describe "GET #edit" do
    before { get :edit, params: { id: course1.id } }
    it "assigns the requested course to @course" do
      expect(assigns(:course)).to eq(course1)
    end
    it "assigns admin users to @admin_users" do
      expect(assigns(:admin_users)).to include(admin_user)
    end
    it "renders the edit template" do
      expect(response).to render_template(:edit)
    end
  end

  # Test cho PATCH #update
  describe "PATCH #update" do
    let!(:course1) { create(:course, title: "Original Title", description: "Original Description", duration: 10) }

    context "with valid params" do
      it "updates the title in the database" do
        new_title = "Updated Title"
        patch :update, params: { id: course1.id, course: { title: new_title } }
        course1.reload
        expect(course1.title).to eq(new_title)
      end

      it "updates the description in the database" do
        new_description = "Updated description"
        patch :update, params: { id: course1.id, course: { description: new_description } }
        course1.reload
        expect(course1.description).to eq(new_description)
      end

      it "updates the duration in the database" do
        new_duration = 200
        patch :update, params: { id: course1.id, course: { duration: new_duration } }
        course1.reload
        expect(course1.duration).to eq(new_duration)
      end

      it "updates course admins in the database" do
        new_admin = create(:user, role: "admin")
        patch :update, params: { id: course1.id, course: { course_admin_ids: [new_admin.id] } }
        course1.reload
        expect(course1.admins).to include(new_admin)
      end

      it "redirects to the course show page" do
        patch :update, params: { id: course1.id, course: { title: "Updated" } }
        expect(response).to redirect_to(admin_course_path(course1))
      end

      it "sets a success flash message" do
        patch :update, params: { id: course1.id, course: { title: "Updated" } }
        expect(flash[:success]).to eq(I18n.t("admin.courses.update_success"))
      end
    end

    context "with invalid params" do
      let(:invalid_attributes) { { title: nil } }

      it "does not update the course" do
        patch :update, params: { id: course1.id, course: invalid_attributes }
        course1.reload
        expect(course1.title).to eq("Original Title")
      end

      it "renders the edit template" do
        patch :update, params: { id: course1.id, course: invalid_attributes }
        expect(response).to render_template(:edit)
      end

      it "assigns admin users to @admin_users" do
        patch :update, params: { id: course1.id, course: invalid_attributes }
        expect(assigns(:admin_users)).to include(admin_user)
      end
    end
  end

  # Test cho DELETE #destroy
  describe "DELETE #destroy" do
    context "when destroy is successful" do
      it "destroys the requested course" do
        expect { delete :destroy, params: { id: course1.id } }.to change(Course, :count).by(-1)
      end
      it "sets a success flash message" do
        delete :destroy, params: { id: course1.id }
        expect(flash[:success]).to eq(I18n.t("admin.courses.destroy.delete_success"))
      end
      it "redirects to the courses index" do
        delete :destroy, params: { id: course1.id }
        expect(response).to redirect_to(admin_courses_path)
      end
    end
    context "when destroy fails" do
      before do
        allow_any_instance_of(Course).to receive(:destroy).and_return(false)
        delete :destroy, params: { id: course1.id }
      end
      it "sets an error flash message" do
        expect(flash[:error]).to eq(I18n.t("admin.courses.destroy.delete_failed"))
      end
    end
  end

  # Test cho before_actions
  describe "before_actions" do
    context "when a user is not logged in as admin" do
      before do
        session[:user_id] = regular_user.id
        get :index
      end
      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.courses.authenticate_admin.not_authorized"))
      end
    end

    context "when course is not found" do
      before { get :show, params: { id: -1 } }
      it "redirects to admin courses path" do
        expect(response).to redirect_to(admin_courses_path)
      end
      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.courses.show.course_not_found"))
      end
    end
  end
end
