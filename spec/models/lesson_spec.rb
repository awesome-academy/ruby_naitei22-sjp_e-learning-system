require "rails_helper"

RSpec.describe Lesson, type: :model do
  let!(:user) { create(:user) }
  let!(:course) { create(:course, creator: user) }

  let!(:lesson1) { create(:lesson, course: course, creator: user, position: 1, title: "English Lesson", created_at: Time.zone.now.beginning_of_day) }
  let!(:lesson2) { create(:lesson, course: course, creator: user, position: 2, title: "French Lesson", created_at: 1.day.ago) }
  let!(:lesson3) { create(:lesson, course: course, creator: user, position: 3, title: "Spanish Lesson", created_at: 7.days.ago) }
  let!(:lesson4) { create(:lesson, course: course, creator: user, position: 4, title: "German Lesson", created_at: 31.days.ago) }

  # Test Validations
  describe "validations" do
    it "is valid with a title, description, and position" do
      lesson = Lesson.new(title: "New Lesson", description: "A new lesson", position: 5, course: course, creator: user)
      expect(lesson).to be_valid
    end

    it "is not valid without a title" do
      lesson = Lesson.new(title: nil, description: "A new lesson", position: 5, course: course, creator: user)
      expect(lesson).not_to be_valid
    end

    it "is not valid without a description" do
      lesson = Lesson.new(title: "New Lesson", description: nil, position: 5, course: course, creator: user)
      expect(lesson).not_to be_valid
    end

    it "is not valid without a position" do
      lesson = Lesson.new(title: "New Lesson", description: "A new lesson", position: nil, course: course, creator: user)
      expect(lesson).not_to be_valid
    end
  end

  # Test Associations
  describe "associations" do
    it "belongs to a course" do
      expect(lesson1.course).to eq(course)
    end

    it "belongs to a creator" do
      expect(lesson1.creator).to eq(user)
    end

    it "has many components" do
      expect(lesson1.components).to be_empty
    end

    it "has many user lessons" do
      expect(lesson1.user_lessons).to be_empty
    end
  end

  # Test Scopes
  describe "scopes" do
    describe ".with_user_lessons_for" do
      let!(:user_lesson) { create(:user_lesson, user: user, lesson: lesson1) }

      it "returns lessons with user lessons for the given user" do
        expect(Lesson.with_user_lessons_for(user)).to match_array([lesson1, lesson2, lesson3, lesson4])
      end
    end

    describe ".by_position" do
      it "returns lessons ordered by position ascending" do
        expect(Lesson.by_position).to eq([lesson1, lesson2, lesson3, lesson4])
      end
    end

    describe ".by_content" do
      context "with a query" do
        it "returns lessons whose title includes the query" do
          expect(Lesson.by_content("English")).to eq([lesson1])
        end
      end

      context "without a query" do
        it "returns all lessons" do
          expect(Lesson.by_content(nil)).to match_array([lesson1, lesson2, lesson3, lesson4])
        end
      end
    end

    describe ".by_time" do
      before do
        allow(Settings.filter_days).to receive(:today).and_return("today")
        allow(Settings.filter_days).to receive(:last_7_days).and_return("last_7_days")
        allow(Settings.filter_days).to receive(:last_30_days).and_return("last_30_days")
      end

      it "returns lessons created today" do
        expect(Lesson.by_time("today")).to eq([lesson1])
      end

      it "returns lessons created in the last 7 days" do
        expect(Lesson.by_time("last_7_days")).to match_array([lesson1, lesson2, lesson3])
      end

      it "returns lessons created in the last 30 days" do
        expect(Lesson.by_time("last_30_days")).to match_array([lesson1, lesson2, lesson3])
      end

      it "returns all lessons with an invalid filter" do
        expect(Lesson.by_time("invalid_filter")).to match_array([lesson1, lesson2, lesson3, lesson4])
      end

      it "returns all lessons without a filter" do
        expect(Lesson.by_time(nil)).to match_array([lesson1, lesson2, lesson3, lesson4])
      end
    end
  end
end
