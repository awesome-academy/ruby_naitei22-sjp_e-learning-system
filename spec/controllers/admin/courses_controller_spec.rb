require "rails_helper"

RSpec.describe Admin::CoursesController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin) { create(:user, role: :admin) }
  let(:course) { create(:course) }
  let(:limit) { Settings.course.page_number }

  let(:ability) do
    obj = Object.new
    obj.extend(CanCan::Ability)
    obj.can :manage, Course
    obj
  end

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in admin
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(controller).to receive(:authorize_admin_area).and_return(true)
  end

  describe "GET #index - list with pagination & search" do
    let!(:courses) { create_list(:course, limit + 3) }

    context "when page=1 without search" do
      before { get :index, params: { page: 1 } }

      it "responds with 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "assigns @courses limited by Settings.course.page_number" do
        expect(assigns(:courses).size).to eq(limit)
      end

      it "assigns @pagy count equals total courses" do
        expect(assigns(:pagy).count).to eq(Course.count)
      end

      it "assigns list objects in recent order (first page)" do
        expect(assigns(:courses).ids).to eq(Course.includes(Course::COURSE_PRELOAD).recent.limit(limit).ids)
      end
    end

    context "when page=2 without search" do
      before { get :index, params: { page: 2 } }

      it "assigns remaining items on page 2" do
        remaining = [Course.count - limit, 0].max
        expected_size = [remaining, limit].min
        expect(assigns(:courses).size).to eq(expected_size)
      end
    end

    context "when searching by title" do
      let!(:matched)   { create(:course, title: "Ruby Mastery") }
      let!(:unmatched) { create(:course, title: "Elixir Journey") }

      before { get :index, params: { page: 1, search: "Ruby" } }

      it "includes matched record" do
        expect(assigns(:courses)).to include(matched)
      end

      it "excludes unmatched record" do
        expect(assigns(:courses)).not_to include(unmatched)
      end
    end
  end

  describe "GET #show" do
    it "responds with 200 OK" do
      get :show, params: { id: course.id }
      expect(response).to have_http_status(:ok)
    end

    it "raises RecordNotFound when id = -1" do
      expect { get :show, params: { id: -1 } }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #new" do
    before { get :new }

    it "responds with 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "assigns @admin_users = User.admin" do
      expect(assigns(:admin_users)).to eq(User.admin)
    end
  end

  describe "POST #create" do
    let(:params_ok) do
      {
        title: "Clean Architecture",
        description: "Build maintainable systems",
        duration: 10
      }
    end

    it "persists course with title matching params" do
      post :create, params: { course: params_ok }
      expect(Course.order(:created_at).last.title).to eq("Clean Architecture")
    end

    it "sets creator = current_user" do
      post :create, params: { course: params_ok }
      expect(Course.order(:created_at).last.creator).to eq(admin)
    end

    it "sets flash success (i18n)" do
      post :create, params: { course: params_ok }
      expect(flash[:success]).to eq(I18n.t("admin.courses.create_success"))
    end

    it "redirects to show page" do
      post :create, params: { course: params_ok }
      c = Course.order(:created_at).last
      expect(response).to redirect_to(admin_course_path(c))
    end

    context "when save fails" do
      before do
        allow_any_instance_of(Course).to receive(:save).and_return(false)
      end

      it "assigns @admin_users = User.admin" do
        post :create, params: { course: params_ok }
        expect(assigns(:admin_users)).to eq(User.admin)
      end

      it "renders new with 422" do
        post :create, params: { course: params_ok }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET #edit" do
    it "responds with 200 OK" do
      get :edit, params: { id: course.id }
      expect(response).to have_http_status(:ok)
    end

    it "assigns @admin_users = User.admin" do
      get :edit, params: { id: course.id }
      expect(assigns(:admin_users)).to eq(User.admin)
    end

    it "assigns course_admin_ids from @course.admins" do
      admin_ids = course.admins.pluck(:id)
      get :edit, params: { id: course.id }
      expect(assigns(:course).course_admin_ids).to eq(admin_ids)
    end

    it "raises RecordNotFound when id = -1" do
      expect { get :edit, params: { id: -1 } }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "PATCH #update" do
    let(:params_update) do
      {
        title: "Refactor Legacy",
        description: "Improve code quality"
      }
    end

    it "updates title matching params" do
      patch :update, params: { id: course.id, course: params_update }
      expect(course.reload.title).to eq("Refactor Legacy")
    end

    it "sets flash success (i18n)" do
      patch :update, params: { id: course.id, course: params_update }
      expect(flash[:success]).to eq(I18n.t("admin.courses.update_success"))
    end

    it "redirects to show page" do
      patch :update, params: { id: course.id, course: params_update }
      expect(response).to redirect_to(admin_course_path(course))
    end

    context "when update fails" do
      let(:ids_from_params) { ["1", "2"] }

      before do
        allow_any_instance_of(Course).to receive(:update).and_return(false)
      end

      it "assigns @admin_users = User.admin" do
        patch :update, params: { id: course.id, course: params_update.merge(course_admin_ids: ids_from_params) }
        expect(assigns(:admin_users)).to eq(User.admin)
      end

      it "assigns course_admin_ids from params" do
        patch :update, params: { id: course.id, course: params_update.merge(course_admin_ids: ids_from_params) }
        expect(assigns(:course).course_admin_ids).to eq(ids_from_params)
      end

      it "renders edit with 422" do
        patch :update, params: { id: course.id, course: params_update }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it "raises RecordNotFound when id = -1" do
      expect {
        patch :update, params: { id: -1, course: params_update }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "DELETE #destroy" do
    let!(:target) { create(:course) }

    it "deletes the course (count -1)" do
      expect {
        delete :destroy, params: { id: target.id }
      }.to change(Course, :count).by(-1)
    end

    it "sets flash success (i18n)" do
      delete :destroy, params: { id: target.id }
      expect(flash[:success]).to eq(I18n.t("admin.courses.delete_success"))
    end

    it "redirects to index" do
      delete :destroy, params: { id: target.id }
      expect(response).to redirect_to(admin_courses_path)
    end

    context "when destroy fails" do
      before { allow_any_instance_of(Course).to receive(:destroy).and_return(false) }

      it "sets flash error (i18n)" do
        delete :destroy, params: { id: target.id }
        expect(flash[:error]).to eq(I18n.t("admin.courses.delete_failed"))
      end
    end

    it "raises RecordNotFound when id = -1" do
      expect {
        delete :destroy, params: { id: -1 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
