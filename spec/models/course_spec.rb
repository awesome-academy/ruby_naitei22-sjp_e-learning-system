require "rails_helper"

RSpec.describe Course, type: :model do
  let!(:user) { create(:user) }
  let!(:admin) { create(:user, role: :admin) }

  # Test Validations
  describe "validations" do
    let!(:existing_course) { create(:course) }

    it "is valid with all valid attributes" do
      course = Course.new(title: "New Course", description: "Valid description.", duration: 1, creator: user)
      expect(course).to be_valid
    end

    it "is not valid without a title" do
      course = Course.new(description: "Valid description.", duration: 1, creator: user)
      expect(course).not_to be_valid
    end

    it "is not valid with a duplicate title" do
      course = Course.new(title: existing_course.title, description: "Valid description.", duration: 1, creator: user)
      expect(course).not_to be_valid
    end

    it "is not valid without a description" do
      course = Course.new(title: "New Course", duration: 1, creator: user)
      expect(course).not_to be_valid
    end

    it "is not valid without a duration" do
      course = Course.new(title: "New Course", description: "Valid description.", creator: user)
      expect(course).not_to be_valid
    end

    it "is not valid with a duration less than or equal to 0" do
      course = Course.new(title: "New Course", description: "Valid description.", duration: 0, creator: user)
      expect(course).not_to be_valid
    end
  end

  # Test Scopes
  describe "scopes" do
    let!(:course1) { create(:course, title: "English A", description: "English A", created_at: 2.days.ago) }
    let!(:course2) { create(:course, title: "English B", description: "English B", created_at: 1.day.ago) }

    describe ".recent" do
      it "returns courses in descending order of creation date" do
        expect(Course.recent).to eq([course2, course1])
      end
    end

    describe ".by_title" do
      it "returns courses whose title includes the keyword" do
        expect(Course.by_title("English")).to match_array([course1, course2])
      end
      it "returns all courses if title is blank" do
        expect(Course.by_title(nil)).to match_array([course1, course2])
      end
    end

    describe ".search_name" do
      it "returns courses whose name includes the keyword" do
        expect(Course.search_name("English")).to match_array([course1, course2])
      end
      it "returns all courses if keyword is blank" do
        expect(Course.search_name(nil)).to match_array([course1, course2])
      end
    end

    describe ".with_status_for_user" do
      let!(:user_course1) { create(:user_course, user: user, course: course1, enrolment_status: :pending) }

      it "returns not enrolled courses" do
        expect(Course.with_status_for_user(:not_enrolled, user)).to match_array([course2])
      end
      it "returns enrolled courses" do
        expect(Course.with_status_for_user(:pending, user)).to match_array([course1])
      end
      it "returns all courses if user is nil" do
        expect(Course.with_status_for_user(:pending, nil)).to match_array([course1, course2])
      end
    end
  end

  # Test Instance Methods
  describe "#progress_percentage_for_user" do
    let(:course) { create(:course) }
    let(:user) { create(:user) }
    let!(:lesson1) { create(:lesson, course: course) }
    let!(:lesson2) { create(:lesson, course: course) }

    context "when user has completed some lessons" do
      before do
        allow(UserLesson).to receive(:count_for_user_and_lessons).and_return(1)
      end
      it "returns the correct progress percentage" do
        expect(course.progress_percentage_for_user(user)).to eq(50)
      end
    end

    context "when user has not completed any lessons" do
      before do
        allow(UserLesson).to receive(:count_for_user_and_lessons).and_return(0)
      end
      it "returns 0 progress percentage" do
        expect(course.progress_percentage_for_user(user)).to eq(0)
      end
    end

    context "when there are no lessons" do
      it "returns 0 progress percentage" do
        course.lessons.destroy_all
        expect(course.progress_percentage_for_user(user)).to eq(0)
      end
    end
  end

  # Test Private Methods
  describe "private methods" do
    let!(:course) { create(:course) }
    let!(:user_ids) { [create(:user, role: :admin).id, create(:user, role: :admin).id] }

    describe "#assign_admin_managers" do
      context "when admin IDs are provided" do
        it "assigns admin course managers" do
          expect { course.send(:assign_admin_managers, user_ids) }.to change(AdminCourseManager, :count).by(2)
        end
      end

      context "when no admin IDs are provided" do
        it "does not change the number of managers" do
          expect { course.send(:assign_admin_managers, []) }.not_to change(AdminCourseManager, :count)
        end
      end
    end
  end
end
