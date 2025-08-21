require "rails_helper"

RSpec.describe Lesson, type: :model do
  let(:course) { create(:course) }
  let(:creator) { create(:user) }

  # Test Validations
  describe "validations" do
    let(:valid_attributes) do
      {
        title: "Introduction to English",
        description: "A basic English lesson",
        position: 1,
        course: course,
        creator: creator
      }
    end

    it "is valid with a title, description, and position" do
      lesson = Lesson.new(valid_attributes)
      expect(lesson).to be_valid
    end

    it "is not valid without a title" do
      lesson = Lesson.new(valid_attributes.merge(title: nil))
      expect(lesson).not_to be_valid
      expect(lesson.errors[:title]).to include("can't be blank")
    end

    it "is not valid without a description" do
      lesson = Lesson.new(valid_attributes.merge(description: nil))
      expect(lesson).not_to be_valid
      expect(lesson.errors[:description]).to include("can't be blank")
    end

    it "is not valid without a position" do
      lesson = Lesson.new(valid_attributes.merge(position: nil))
      expect(lesson).not_to be_valid
      expect(lesson.errors[:position]).to include("can't be blank")
    end
  end

  # Test Associations
  describe "associations" do
    let(:lesson) { create(:lesson) }

    it "belongs to a course" do
      expect(lesson.course).to be_present
    end

    it "belongs to a creator" do
      expect(lesson.creator).to be_present
    end

    it "has many components" do
      expect(lesson.components).to be_present
    end

    it "has many user_lessons" do
      expect(lesson.user_lessons).to be_present
    end
  end

  # Test Scopes
  describe "scopes" do
    let!(:lesson1) { create(:lesson, course: course, creator: creator, position: 1, title: "English Lesson", created_at: Time.zone.now.beginning_of_day) }
    let!(:lesson2) { create(:lesson, course: course, creator: creator, position: 2, title: "French Lesson", created_at: 1.day.ago) }
    let!(:lesson3) { create(:lesson, course: course, creator: creator, position: 3, title: "Spanish Lesson", created_at: 7.days.ago) }

    describe ".with_user_lessons_for" do
      let(:user) { create(:user) }
      let!(:user_lesson) { create(:user_lesson, user: user, lesson: lesson1) }

      it "returns lessons with user lessons for the given user" do
        expect(Lesson.with_user_lessons_for(user)).to include(lesson1)
      end

      it "does not return lessons without user lessons for the given user" do
        expect(Lesson.with_user_lessons_for(user)).not_to include(lesson2)
      end
    end

    describe ".by_position" do
      it "returns lessons ordered by position ascending" do
        expect(Lesson.by_position).to eq([lesson1, lesson2, lesson3])
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
          expect(Lesson.by_content(nil)).to match_array([lesson1, lesson2, lesson3])
        end
      end
    end

    describe ".by_time" do
      context "with 'today' filter" do
        it "returns lessons created today" do
          expect(Lesson.by_time("today")).to eq([lesson1])
        end
      end

      context "with 'last_7_days' filter" do
        it "returns lessons created in the last 7 days" do
          expect(Lesson.by_time("last_7_days")).to match_array([lesson1, lesson2, lesson3])
        end
      end

      context "with 'last_30_days' filter" do
        it "returns lessons created in the last 30 days" do
          expect(Lesson.by_time("last_30_days")).to match_array([lesson1, lesson2, lesson3])
        end
      end

      context "with an invalid filter" do
        it "returns all lessons" do
          expect(Lesson.by_time("invalid_filter")).to match_array([lesson1, lesson2, lesson3])
        end
      end
    end
  end
end
