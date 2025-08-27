require "rails_helper"

RSpec.describe UserCourse, type: :model do
  # Test Validations
  describe "validations" do
    let(:user_course) { create(:user_course) }

    it "is valid with default attributes" do
      expect(user_course).to be_valid
    end

    it "is not valid without a reason if rejected" do
      user_course.enrolment_status = :rejected
      user_course.reason = nil
      expect(user_course).not_to be_valid
    end

    it "is valid without a reason if not rejected" do
      user_course.enrolment_status = :pending
      user_course.reason = nil
      expect(user_course).to be_valid
    end
  end

  # Test Scopes
  describe "scopes" do
    let!(:user) { create(:user) }
    let!(:course1) { create(:course) }
    let!(:course2) { create(:course) }
    let!(:pending_uc) { create(:user_course, user: user, course: course1, enrolment_status: :pending) }
    let!(:approved_uc) { create(:user_course, user: user, course: course1, enrolment_status: :approved) }
    let!(:rejected_uc) { create(:user_course, user: user, course: course2, enrolment_status: :rejected, reason: "Test reason") }
    let!(:in_progress_uc) { create(:user_course, user: user, course: course2, enrolment_status: :in_progress) }
    let!(:completed_uc) { create(:user_course, user: user, course: course1, enrolment_status: :completed) }

    describe ".approved_statuses" do
      it "returns user courses with approved statuses" do
        expect(UserCourse.approved_statuses).to match_array([approved_uc, in_progress_uc, completed_uc])
      end
    end

    describe ".with_status_in" do
      it "returns user courses with specified statuses" do
        expect(UserCourse.with_status_in(:pending)).to eq([pending_uc])
      end
      it "returns all user courses if status is blank" do
        expect(UserCourse.with_status_in(nil)).to match_array(UserCourse.all)
      end
    end

    describe ".recent" do
      it "returns user courses in descending order of creation date" do
        expect(UserCourse.recent).to eq([completed_uc, in_progress_uc, rejected_uc, approved_uc, pending_uc])
      end
    end

    describe ".by_course" do
      it "returns user courses for a specific course" do
        expect(UserCourse.by_course(course1.id)).to match_array([pending_uc, approved_uc, completed_uc])
      end
      it "returns all user courses if course_id is blank" do
        expect(UserCourse.by_course(nil)).to match_array(UserCourse.all)
      end
    end

    describe ".by_status" do
      it "returns user courses with a specific status" do
        expect(UserCourse.by_status(:pending)).to eq([pending_uc])
      end
      it "returns all user courses if status is blank" do
        expect(UserCourse.by_status(nil)).to match_array(UserCourse.all)
      end
    end

    describe ".registered_from" do
      it "returns user courses registered from a specific date" do
        expect(UserCourse.registered_from(2.days.ago)).to match_array(UserCourse.where("created_at >= ?", 2.days.ago))
      end
      it "returns all user courses if date is blank" do
        expect(UserCourse.registered_from(nil)).to match_array(UserCourse.all)
      end
    end

    describe ".expiration_date" do
      it "returns user courses with a specific expiration date" do
        expect(UserCourse.expiration_date(1.day.ago)).to match_array(UserCourse.where("created_at <= ?", 1.day.ago))
      end
      it "returns all user courses if date is blank" do
        expect(UserCourse.expiration_date(nil)).to match_array(UserCourse.all)
      end
    end

    describe ".approvable" do
      it "returns user courses with approvable statuses" do
        expect(UserCourse.approvable).to match_array([pending_uc, rejected_uc])
      end
    end

    describe ".rejectable" do
      it "returns user courses with rejectable statuses" do
        expect(UserCourse.rejectable).to match_array([pending_uc, approved_uc])
      end
    end

    describe ".invalid_for_approve" do
      it "returns user courses with invalid statuses for approval" do
        expect(UserCourse.invalid_for_approve).to match_array([approved_uc, in_progress_uc])
      end
    end

    describe ".invalid_for_reject" do
      it "returns user courses with invalid statuses for rejection" do
        expect(UserCourse.invalid_for_reject).to match_array([rejected_uc, in_progress_uc])
      end
    end
  end
end
