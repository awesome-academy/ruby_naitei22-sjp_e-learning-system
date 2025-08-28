require "rails_helper"

RSpec.describe Admin::LessonsController, type: :controller do
  let(:admin){create(:user, :admin)}
  let(:course){create(:course)}
  let(:lesson){create(:lesson, course:)}

  before{sign_in admin}

  describe "GET #new" do
    before{get :new, params: {course_id: course.id}}

    it{expect(assigns(:lesson)).to be_a_new(Lesson)}
    it{expect(assigns(:selected_word_ids)).to eq []}
    it{expect(assigns(:selected_test_ids)).to eq []}
    it{expect(assigns(:selected_paragraphs)).to eq []}
    it{expect(response).to render_template(:new)}
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        course_id: course.id,
        locale: :en,
        lesson: {
          title: "Title",
          description: "Desc",
          word_ids: [""],
          test_ids: [""],
          paragraphs: [{content: "Para"}]
        }
      }
    end

    context "success" do
      before{post :create, params: valid_params}

      it{expect(flash[:success]).to be_present}
      it{        expect(response).to redirect_to(admin_course_lesson_path(course,
                                                                 assigns(:lesson)))
      }
    end

    context "failure" do
      before do
        allow_any_instance_of(Lesson).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(lesson))
        post :create, params: valid_params
      end

      it{expect(assigns(:error_object)).to eq lesson}
      it{expect(response).to have_http_status(:unprocessable_entity)}
    end
  end

  describe "GET #edit" do
    let!(:word_component) do
      create(:component, :word, lesson:, index_in_lesson: 1)
    end
    let!(:test_component) do
      create(:component, :test, lesson:, index_in_lesson: 2)
    end
    let!(:paragraph_component) do
      create(:component, :paragraph, lesson:,
index_in_lesson: 3)
    end

    before{get :edit, params: {course_id: course.id, id: lesson.id}}

    it{expect(assigns(:selected_word_ids)).to eq [word_component.word_id]}
    it{expect(assigns(:selected_test_ids)).to eq [test_component.test_id]}
    it{      expect(assigns(:selected_paragraphs)).to eq [paragraph_component.content]
    }
    it{expect(response).to render_template(:edit)}
  end

  describe "PATCH #update" do
    let(:update_params) do
      {
        course_id: course.id,
        id: lesson.id,
        lesson: {title: "Updated", word_ids: [], test_ids: [], paragraphs: []}
      }
    end

    context "success" do
      before{patch :update, params: update_params}

      it{expect(flash[:success]).to be_present}
      it{        expect(response).to redirect_to(admin_course_lesson_path(course,
                                                                 lesson))
      }
    end

    context "failure" do
      before do
        allow_any_instance_of(Lesson).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(lesson))
        patch :update, params: update_params
      end

      it{expect(assigns(:error_object)).to eq lesson}
    end
  end

  describe "GET #index" do
    let!(:l1){create(:lesson, course:, position: 1)}
    let!(:l2){create(:lesson, course:, position: 2)}
    let!(:l3){create(:lesson, course:, position: 3)}

    before{get :index, params: {course_id: course.id, locale: :en}}

    it "assigns lessons ordered" do
      expect(assigns(:lessons).map(&:id)).to eq [l1.id, l2.id, l3.id]
    end

    it "filters by query" do
      get :index, params: {course_id: course.id, query: "abc"}
      expect(assigns(:lessons)).to all(have_attributes(title: a_string_including("abc")))
    end

    it "filters by time" do
      get :index, params: {course_id: course.id, filter_time: "today"}
      expect(assigns(:lessons)).to all(be_a(Lesson))
    end
  end

  describe "GET #show" do
    before{get :show, params: {course_id: course.id, id: lesson.id}}
    it{expect(response).to render_template(:show)}
  end

  describe "DELETE #destroy" do
    context "success" do
      before do
        delete :destroy, params: {course_id: course.id, id: lesson.id}
      end

      it{expect(flash[:success]).to be_present}
      it{expect(response).to redirect_to(admin_course_lessons_path(course))}
    end

    context "failure" do
      before do
        allow_any_instance_of(Lesson).to receive(:destroy).and_return(false)
        delete :destroy, params: {course_id: course.id, id: lesson.id}
      end

      it{expect(flash[:danger]).to be_present}
      it{expect(response).to redirect_to(admin_course_lessons_path(course))}
    end
  end

  describe "private helpers" do
    describe "#consolidate_components_data" do
      it "combines paragraphs, words, and tests" do
        data = controller.send(:consolidate_components_data, {
                                 paragraphs: [{"content" => "p"}],
                                 word_ids: %w(1),
                                 test_ids: %w(2)
                               })
        expect(data.pluck(:type)).to include(Settings.component_types.paragraph,
                                             Settings.component_types.word,
                                             Settings.component_types.test)
      end
    end

    describe "#build_component_attributes" do
      it "creates component attrs correctly" do
        lesson_obj = create(:lesson, course:)
        data = [{type: Settings.component_types.word, id: 5}]
        attrs = controller.send(:build_component_attributes, lesson_obj,
                                data).first
        expect(attrs[:word_id]).to eq 5
      end
    end

    describe "#set_course" do
      it "redirects when course not found" do
        get :index, params: {course_id: 0}
        expect(response).to redirect_to(admin_courses_path)
      end
    end

    describe "#set_lesson" do
      it "redirects when lesson not found" do
        get :show, params: {course_id: course.id, id: 0}
        expect(response).to redirect_to(admin_course_path(course))
      end
    end
  end
end
