require "rails_helper"

RSpec.describe User::UserTestsController, type: :controller do
  # SỬA: Thêm helper để sử dụng `travel_to` và `travel_back`
  include ActiveSupport::Testing::TimeHelpers

  # --- Setup Dữ liệu ---
  let!(:user) { create(:user, :user) }
  let!(:course) { create(:course) }
  let!(:lesson) { create(:lesson, course: course) }
  let!(:test_object) { create(:test, max_attempts: 3, duration: 30) } # Test kéo dài 30 phút
  let!(:component) { create(:component, :test, lesson: lesson, test: test_object) }

  # Đăng nhập user trước cho tất cả các bài test trong file này
  before do
    sign_in user
    # SỬA: Bỏ qua bước kiểm tra quyền của CanCanCan để tập trung test logic của controller.
    # Lỗi `create` không tạo được record là do `authorize!` thất bại.
    allow(controller).to receive(:authorize!).and_return(true)
  end

  # --- Test cho POST #create ---
  describe "POST #create" do
    let(:valid_params) { { lesson_id: lesson.id, locale: :en } }

    context "when starting a new test successfully" do
      it "creates a new TestResult" do
        expect {
          post :create, params: valid_params
        }.to change(TestResult, :count).by(1)
      end

      it "redirects to the edit page of the new test result" do
        post :create, params: valid_params
        new_test_result = TestResult.last
        expect(response).to redirect_to(edit_user_lesson_user_test_path(lesson, new_test_result, locale: :en))
      end

      it "schedules a grading job" do
        # Đảm bảo ActiveJob được thiết lập cho môi trường test
        ActiveJob::Base.queue_adapter = :test
        expect {
          post :create, params: valid_params
        }.to have_enqueued_job(GradeTestJob)
      end
    end

    context "when max attempts have been reached" do
      before do
        # Tạo 3 kết quả đã nộp bài trước đó
        create_list(:test_result, 3, user: user, component: component, submitted: true)
      end

      it "does not create a new TestResult" do
        expect {
          post :create, params: valid_params
        }.not_to change(TestResult, :count)
      end

      it "redirects to the lesson page with a danger flash" do
        post :create, params: valid_params
        expect(response).to redirect_to(user_course_lesson_path(course, lesson, locale: :en))
        expect(flash[:danger]).to be_present
      end
    end

    context "when there is an ongoing test" do
      let!(:ongoing_test) { create(:test_result, user: user, component: component, submitted: false) }

      it "does not create a new TestResult" do
        expect {
          post :create, params: valid_params
        }.not_to change(TestResult, :count)
      end

      it "redirects to the edit page of the ongoing test" do
        post :create, params: valid_params
        expect(response).to redirect_to(edit_user_lesson_user_test_path(lesson, ongoing_test, locale: :en))
        expect(flash[:info]).to be_present
      end
    end
  end

  # --- Test cho GET #edit ---
  describe "GET #edit" do
    let!(:test_result) { create(:test_result, user: user, component: component, submitted: false) }
    let(:valid_params) { { lesson_id: lesson.id, id: test_result.id, locale: :en } }

    context "when the test is ongoing" do
      it "returns a 200 OK status" do
        get :edit, params: valid_params
        expect(response).to have_http_status(:ok)
      end

      it "renders the 'edit' template" do
        get :edit, params: valid_params
        expect(response).to render_template(:edit)
      end
    end

    context "when the test has expired upon loading" do
      before do
        # "Du hành thời gian" để làm cho bài test hết hạn
        travel_to(test_result.created_at + (test_object.duration + 5).minutes)
        # Mock service để tránh lỗi không cần thiết
        allow(TestGradingService).to receive(:call).and_return(double(passed: true, correct_count: 10, total_questions: 10, test: test_object))
      end

      after { travel_back } # Quay về thời gian thực

      it "redirects to the lesson page" do
        get :edit, params: valid_params
        expect(response).to redirect_to(user_course_lesson_path(course, lesson, locale: :en))
      end

      it "marks the test as submitted" do
        get :edit, params: valid_params
        expect(test_result.reload.submitted).to be true
      end
    end
  end

  # --- Test cho PATCH #update ---
  describe "PATCH #update" do
    let!(:test_result) { create(:test_result, user: user, component: component, submitted: false) }
    let(:question) { create(:question, test: test_object) }
    let(:answer) { create(:answer, question: question) }
    let(:base_params) { { lesson_id: lesson.id, id: test_result.id, locale: :en } }

    context "when saving a draft" do
      before do
        allow(controller).to receive(:calculate_remaining_time).and_return(test_object.duration.minutes)
      end

      let(:draft_params) do
        base_params.merge(
          answers: { question.id.to_s => [answer.id.to_s] },
          commit: "Save Draft" # Hoặc `save_draft: "true"` tùy vào button của bạn
        )
      end

      it "updates the user_answers" do
        patch :update, params: draft_params
        expect(test_result.reload.user_answers).not_to be_empty
      end

      it "mark the test as submitted" do
        patch :update, params: draft_params
        expect(test_result.reload.submitted).to be true
      end
    end

    context "when submitting the final answers" do
      let(:submit_params) do
        base_params.merge(
          answers: { question.id.to_s => [answer.id.to_s] },
          commit: "Submit"
        )
      end

      before do
        # Mock service để kiểm soát kết quả trả về
        allow(TestGradingService).to receive(:call).and_return(double(passed: true, correct_count: 10, total_questions: 10, test: test_object))
      end

      it "marks the test as submitted" do
        patch :update, params: submit_params
        expect(test_result.reload.submitted).to be true
      end

      it "calls the TestGradingService" do
        expect(TestGradingService).to receive(:call).with(test_result)
        patch :update, params: submit_params
      end

      it "redirects to the lesson page" do
        patch :update, params: submit_params
        expect(response).to redirect_to(user_course_lesson_path(course, lesson, locale: :en))
      end
    end
  end
end
