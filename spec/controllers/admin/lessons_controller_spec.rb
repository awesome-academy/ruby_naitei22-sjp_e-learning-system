require "rails_helper"

RSpec.describe Admin::LessonsController, type: :controller do
  let!(:admin_user) { create(:user, role: "admin") }
  let!(:course) { create(:course, creator: admin_user) }
  let!(:lesson1) { create(:lesson, course: course, creator: admin_user, position: 1) }

  def login_as_admin
    session[:user_id] = admin_user.id
  end

  before do
    login_as_admin
  end

  # Test cho GET #index
  describe "GET #index" do
    before { get :index, params: { course_id: course.id } }

    it "assigns all lessons for the course to @lessons" do
      expect(assigns(:lessons)).to eq([lesson1])
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end
  end

  # Test cho GET #new
  describe "GET #new" do
    before { get :new, params: { course_id: course.id } }

    it "assigns a new lesson to @lesson" do
      expect(assigns(:lesson)).to be_a_new(Lesson)
    end

    it "renders the new template" do
      expect(response).to render_template(:new)
    end
  end

  # Test cho POST #create
  describe "POST #create" do
    let(:valid_params) do
      {
        lesson: {
          title: "New Lesson",
          description: "New description",
          word_ids: ["", create(:word).id],
          test_ids: ["", create(:test).id],
          paragraphs: [{ content: "Paragraph content" }]
        },
        course_id: course.id
      }
    end

    context "with valid params" do
      it "creates a new lesson" do
        expect { post :create, params: valid_params }.to change(Lesson, :count).by(1)
      end

      it "redirects to the lesson show page" do
        post :create, params: valid_params
        expect(response).to redirect_to(admin_course_lesson_path(course, Lesson.last))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          lesson: {
            title: nil,
            description: nil
          },
          course_id: course.id
        }
      end

      it "does not create a new lesson" do
        expect { post :create, params: invalid_params }.not_to change(Lesson, :count)
      end

      it "renders the new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  # Test cho GET #edit
  describe "GET #edit" do
    before { get :edit, params: { course_id: course.id, id: lesson1.id } }

    it "assigns the requested lesson to @lesson" do
      expect(assigns(:lesson)).to eq(lesson1)
    end

    it "renders the edit template" do
      expect(response).to render_template(:edit)
    end
  end

  # Test cho PATCH #update
  describe "PATCH #update" do
    # Đảm bảo các thuộc tính ban đầu để có thể cập nhật
    let!(:original_lesson) { create(:lesson, course: course, creator: admin_user) }

    context "with valid params" do
      it "updates the title in the database" do
        new_title = "Updated Title"
        patch :update, params: { course_id: course.id, id: original_lesson.id, lesson: { title: new_title } }
        original_lesson.reload
        expect(original_lesson.title).to eq(new_title)
      end

      it "updates the description in the database" do
        new_description = "Updated description"
        patch :update, params: { course_id: course.id, id: original_lesson.id, lesson: { description: new_description } }
        original_lesson.reload
        expect(original_lesson.description).to eq(new_description)
      end

      it "redirects to the lesson show page" do
        patch :update, params: { course_id: course.id, id: original_lesson.id, lesson: { title: "Updated" } }
        expect(response).to redirect_to(admin_course_lesson_path(course, original_lesson))
      end
    end

    context "with invalid params" do
      let(:invalid_attributes) { { title: nil } }

      it "assigns the invalid lesson to @lesson" do
        patch :update, params: { course_id: course.id, id: lesson1.id, lesson: invalid_attributes }
        expect(assigns(:lesson)).to eq(lesson1)
      end
    end
  end

  # Test cho DELETE #destroy
  describe "DELETE #destroy" do
    it "destroys the requested lesson" do
      expect { delete :destroy, params: { course_id: course.id, id: lesson1.id } }.to change(Lesson, :count).by(-1)
    end

    it "redirects to the lessons index" do
      delete :destroy, params: { course_id: course.id, id: lesson1.id }
      expect(response).to redirect_to(admin_course_lessons_path(course))
    end
  end
end
