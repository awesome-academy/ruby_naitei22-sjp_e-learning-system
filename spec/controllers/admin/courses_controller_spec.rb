require "rails_helper"

RSpec.describe Admin::CoursesController, type: :controller do
  let!(:admin_user){create(:user, :admin)}
  let!(:course){create(:course, creator: admin_user)}

  before{sign_in admin_user}

  # --- Test cho GET #index ---
  describe "GET #index" do
    before{get :index}

    it "returns a successful http status" do
      expect(response).to have_http_status(:ok)
    end

    it "assigns @courses" do
      expect(assigns(:courses)).to include(course)
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end
  end

  # --- Test cho GET #show ---
  describe "GET #show" do
    context "with a valid course ID" do
      before{get :show, params: {id: course.id}}

      it "returns a successful http status" do
        expect(response).to have_http_status(:ok)
      end

      it "assigns the requested course to @course" do
        expect(assigns(:course)).to eq(course)
      end

      it "renders the show template" do
        expect(response).to render_template(:show)
      end
    end

    context "with an invalid course ID" do
      before{get :show, params: {id: -1}}

      it "redirects to the courses index page" do
        expect(response).to redirect_to(admin_courses_path)
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to be_present
      end
    end
  end

  # --- Test cho GET #new ---
  describe "GET #new" do
    before{get :new}

    it "returns a successful http status" do
      expect(response).to have_http_status(:ok)
    end

    it "assigns a new Course to @course" do
      expect(assigns(:course)).to be_a_new(Course)
    end

    it "renders the new template" do
      expect(response).to render_template(:new)
    end
  end

  # --- Test cho POST #create ---
  describe "POST #create" do
    let(:valid_attributes){attributes_for(:course)}
    let(:invalid_attributes){attributes_for(:course, title: "")}

    context "with valid parameters" do
      it "creates a new Course" do
        expect do
          post :create, params: {course: valid_attributes}
        end.to change(Course, :count).by(1)
      end

      it "redirects to the created course's page" do
        post :create, params: {course: valid_attributes}
        expect(response).to redirect_to(admin_course_path(Course.last))
      end

      it "sets a success flash message" do
        post :create, params: {course: valid_attributes}
        expect(flash[:success]).to be_present
      end
    end

    context "with invalid parameters" do
      before{post :create, params: {course: invalid_attributes}}

      it "does not create a new Course" do
        expect do
          post :create, params: {course: invalid_attributes}
        end.not_to change(Course, :count)
      end

      it "re-renders the 'new' template" do
        expect(response).to render_template(:new)
      end

      it "returns an unprocessable_entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # --- Test cho GET #edit ---
  describe "GET #edit" do
    before{get :edit, params: {id: course.id}}

    it "returns a successful http status" do
      expect(response).to have_http_status(:ok)
    end

    it "assigns the requested course to @course" do
      expect(assigns(:course)).to eq(course)
    end

    it "renders the edit template" do
      expect(response).to render_template(:edit)
    end
  end

  # --- Test cho PATCH #update ---
  describe "PATCH #update" do
    let(:new_attributes){{title: "New Updated Course Title"}}

    context "with valid parameters" do
      before do
        patch :update, params: {id: course.id, course: new_attributes}
      end

      it "updates the requested course's title" do
        expect(course.reload.title).to eq("New Updated Course Title")
      end

      it "redirects to the course's page" do
        expect(response).to redirect_to(admin_course_path(course))
      end

      it "sets a success flash message" do
        expect(flash[:success]).to be_present
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes){{title: ""}}
      before do
        patch :update, params: {id: course.id, course: invalid_attributes}
      end

      it "does not update the course's title" do
        expect(course.reload.title).not_to eq("")
      end

      it "re-renders the 'edit' template" do
        expect(response).to render_template(:edit)
      end

      it "returns an unprocessable_entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # --- Test cho DELETE #destroy ---
  describe "DELETE #destroy" do
    let!(:course_to_delete){create(:course)}

    context "when destroy is successful" do
      it "destroys the requested course" do
        expect do
          delete :destroy, params: {id: course_to_delete.id}
        end.to change(Course, :count).by(-1)
      end

      it "redirects to the courses index page" do
        delete :destroy, params: {id: course_to_delete.id}
        expect(response).to redirect_to(admin_courses_path)
      end

      it "sets a success flash message" do
        delete :destroy, params: {id: course_to_delete.id}
        expect(flash[:success]).to be_present
      end
    end

    context "when destroy fails" do
      before do
        allow_any_instance_of(Course).to receive(:destroy).and_return(false)
      end

      it "does not destroy the course" do
        expect do
          delete :destroy, params: {id: course_to_delete.id}
        end.not_to change(Course, :count)
      end

      it "redirects to the courses index page" do
        delete :destroy, params: {id: course_to_delete.id}
        expect(response).to redirect_to(admin_courses_path)
      end

      it "sets an error flash message" do
        delete :destroy, params: {id: course_to_delete.id}
        expect(flash[:error]).to be_present
      end
    end
  end
end
