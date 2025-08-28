require "rails_helper"

RSpec.describe Admin::LessonsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin)  { create(:user, role: :admin) }
  let(:course) { create(:course) }

  let(:ability) do
    obj = Object.new
    obj.extend(CanCan::Ability)
    obj.can :manage, Course
    obj.can :manage, Lesson
    obj.can :manage, Component
    obj.can :read,   Word
    obj.can :read,   Test
    obj
  end

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in admin
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(controller).to receive(:authorize_admin_area).and_return(true)
  end

  describe "GET #new" do
    before { get :new, params: { course_id: course.id } }

    it "assigns @selected_word_ids as empty array" do
      expect(assigns(:selected_word_ids)).to eq([])
    end

    it "assigns @selected_test_ids as empty array" do
      expect(assigns(:selected_test_ids)).to eq([])
    end

    it "assigns @selected_paragraphs as empty array" do
      expect(assigns(:selected_paragraphs)).to eq([])
    end

    it "responds with 200 OK" do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    let!(:word1) { create(:word) }
    let!(:test1) { create(:test, duration: 5) }

    let(:lesson_core) { { title: "Intro", description: "First lesson" } }
    let(:components_payload) do
      {
        word_ids:       [word1.id],
        test_ids:       [test1.id],
        paragraphs:     [{ content: "Para 1" }]
      }
    end
    let(:payload) { lesson_core.merge(components_payload) }

    before { allow(controller).to receive(:lesson_params).and_return(lesson_core) }

    it "creates lesson with matching title" do
      post :create, params: { course_id: course.id, lesson: payload }
      expect(course.lessons.order(:created_at).last.title).to eq("Intro")
    end

    it "calls insert_all! once" do
      expect(Component).to receive(:insert_all!).once.and_call_original
      post :create, params: { course_id: course.id, lesson: payload }
    end

    it "creates exactly 3 components" do
      post :create, params: { course_id: course.id, lesson: payload }
      expect(course.lessons.last.components.count).to eq(3)
    end

    it "sets flash success i18n" do
      post :create, params: { course_id: course.id, lesson: payload }
      expect(flash[:success]).to eq(I18n.t("admin.lessons.create.success"))
    end

    it "redirects to lesson show" do
      post :create, params: { course_id: course.id, lesson: payload }
      lesson = course.lessons.order(:created_at).last
      expect(response).to redirect_to(admin_course_lesson_path(course, lesson))
    end

    context "when save! raises RecordInvalid" do
      it "renders :new with 422" do
        allow_any_instance_of(Lesson).to receive(:save!).and_raise(
          ActiveRecord::RecordInvalid.new(build(:lesson))
        )
        post :create, params: { course_id: course.id, lesson: payload }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "keeps selected ids and paragraphs in assigns" do
        allow_any_instance_of(Lesson).to receive(:save!).and_raise(
          ActiveRecord::RecordInvalid.new(build(:lesson))
        )
        post :create, params: { course_id: course.id, lesson: payload }
        expect(assigns(:selected_word_ids)).to eq([word1.id])
      end
    end

    it "raises RecordNotFound when course_id = -1" do
      expect {
        post :create, params: { course_id: -1, lesson: payload }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #edit" do
    let!(:lesson) { create(:lesson, course: course, title: "L1") }
    let!(:word_a) { create(:word) }
    let!(:test_a) { create(:test, duration: 4) }

    before do
      # tạo components theo đúng index_in_lesson
      create(:component, :word,     lesson: lesson, index_in_lesson: 1, word: word_a)
      create(:component, :test,     lesson: lesson, index_in_lesson: 2, test: test_a)
      create(:component, :paragraph, lesson: lesson, index_in_lesson: 3, content: "P1")
    end

    it "assigns selected_word_ids ordered" do
      get :edit, params: { course_id: course.id, id: lesson.id }
      expect(assigns(:selected_word_ids)).to eq([word_a.id])
    end

    it "assigns selected_test_ids ordered" do
      get :edit, params: { course_id: course.id, id: lesson.id }
      expect(assigns(:selected_test_ids)).to eq([test_a.id])
    end

    it "assigns selected_paragraphs ordered" do
      get :edit, params: { course_id: course.id, id: lesson.id }
      expect(assigns(:selected_paragraphs)).to eq(["P1"])
    end
  end

  describe "PATCH #update" do
    let!(:lesson) { create(:lesson, course: course, title: "Old") }
    let!(:word1)  { create(:word) }
    let!(:test1)  { create(:test, duration: 3) }

    let(:core_update) { { title: "New Title", description: "Updated" } }
    let(:components_payload) do
      {
        word_ids:   [word1.id],
        test_ids:   [test1.id],
        paragraphs: [{ content: "NP" }]
      }
    end
    let(:payload) { core_update.merge(components_payload) }

    before { allow(controller).to receive(:lesson_params).and_return(core_update) }

    it "updates lesson title" do
      patch :update, params: { course_id: course.id, id: lesson.id, lesson: payload }
      expect(lesson.reload.title).to eq("New Title")
    end

    it "calls insert_all! once" do
      expect(Component).to receive(:insert_all!).once.and_call_original
      patch :update, params: { course_id: course.id, id: lesson.id, lesson: payload }
    end

    it "ends up with exactly 3 components" do
      patch :update, params: { course_id: course.id, id: lesson.id, lesson: payload }
      expect(lesson.components.count).to eq(3)
    end

    it "sets flash success i18n" do
      patch :update, params: { course_id: course.id, id: lesson.id, lesson: payload }
      expect(flash[:success]).to eq(I18n.t("admin.lessons.update.success"))
    end

    it "redirects to lesson show" do
      patch :update, params: { course_id: course.id, id: lesson.id, lesson: payload }
      expect(response).to redirect_to(admin_course_lesson_path(course, lesson))
    end

    context "when update! raises RecordInvalid" do
      it "assigns @error_object" do
        allow_any_instance_of(Lesson).to receive(:update!).and_raise(
          ActiveRecord::RecordInvalid.new(build(:lesson))
        )
        patch :update, params: { course_id: course.id, id: lesson.id, lesson: payload }
        expect(assigns(:error_object)).to be_a(Lesson)
      end
    end

    it "raises RecordNotFound when id = -1" do
      expect {
        patch :update, params: { course_id: course.id, id: -1, lesson: payload }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #index" do
    let!(:l1) { create(:lesson, course: course, title: "Alpha",  created_at: 10.days.ago) }
    let!(:l2) { create(:lesson, course: course, title: "Bravo",  created_at: 3.days.ago) }
    let!(:l3) { create(:lesson, course: course, title: "AlphaX", created_at: Time.zone.now) }
    let(:per_page) { Settings.lesson.pagy_items }

    it "paginates with given items count" do
      get :index, params: { course_id: course.id, page: 1 }
      expect(assigns(:lessons).size).to be <= per_page
    end

    it "filters by content when query present" do
      get :index, params: { course_id: course.id, query: "Alpha" }
      expect(assigns(:lessons)).to include(l1, l3)
    end

    it "filters by time when filter_time present" do
      get :index, params: { course_id: course.id, filter_time: Settings.filter_days.last_7_days }
      expect(assigns(:lessons)).to include(l2, l3)
    end
  end

  describe "GET #show" do
    let!(:lesson) { create(:lesson, course: course) }

    it "responds with 200 OK" do
      get :show, params: { course_id: course.id, id: lesson.id }
      expect(response).to have_http_status(:ok)
    end

    it "raises RecordNotFound when id = -1" do
      expect {
        get :show, params: { course_id: course.id, id: -1 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "DELETE #destroy" do
    let!(:lesson) { create(:lesson, course: course) }

    it "deletes the lesson (count -1)" do
      expect {
        delete :destroy, params: { course_id: course.id, id: lesson.id }
      }.to change(Lesson, :count).by(-1)
    end

    it "sets flash success i18n" do
      delete :destroy, params: { course_id: course.id, id: lesson.id }
      expect(flash[:success]).to eq(I18n.t("admin.lessons.destroy.success"))
    end

    it "redirects to admin_course_lessons_path" do
      delete :destroy, params: { course_id: course.id, id: lesson.id }
      expect(response).to redirect_to(admin_course_lessons_path(course))
    end

    context "when destroy fails" do
      it "sets flash danger i18n" do
        allow_any_instance_of(Lesson).to receive(:destroy).and_return(false)
        delete :destroy, params: { course_id: course.id, id: lesson.id }
        expect(flash[:danger]).to eq(I18n.t("admin.lessons.destroy.failure"))
      end
    end
  end
end
