require "rails_helper"

RSpec.describe User, type: :model do

  before(:suite) do
    stub_const("Settings", OpenStruct.new(user: OpenStruct.new(max_name_length: 50, max_email_length: 255, hundred_years: 100)))
  end

  # Test Validations
  describe "validations" do
    let(:valid_attributes) do
      {
        name: "Test User",
        email: "test.user@example.com",
        password: "password",
        password_confirmation: "password",
        birthday: "2000-01-01",
        gender: :male
      }
    end

    it "is valid with all required attributes" do
      user = User.new(valid_attributes)
      expect(user).to be_valid
    end

    describe "name" do
      it "is not valid without a name" do
        user = User.new(valid_attributes.merge(name: nil))
        expect(user).not_to be_valid
      end
      it "is not valid with a name longer than max length" do
        user = User.new(valid_attributes.merge(name: "a" * (Settings.user.max_name_length + 1)))
        expect(user).not_to be_valid
      end
    end

    describe "email" do
      it "is not valid without an email" do
        user = User.new(valid_attributes.merge(email: nil))
        expect(user).not_to be_valid
      end
      it "is not valid with an invalid email format" do
        user = User.new(valid_attributes.merge(email: "invalid_email"))
        expect(user).not_to be_valid
      end
      it "is not valid with a duplicate email" do
        create(:user, email: "test.user@example.com")
        user = User.new(valid_attributes)
        expect(user).not_to be_valid
      end
      it "is valid when email is unique and case insensitive" do
        create(:user, email: "test.user@example.com")
        user = User.new(valid_attributes.merge(email: "TEST.USER@example.com"))
        expect(user).not_to be_valid
      end
    end

    describe "password" do
      it "is not valid without a password" do
        user = User.new(valid_attributes.merge(password: nil))
        expect(user).not_to be_valid
      end
      it "is not valid when password confirmation does not match" do
        user = User.new(valid_attributes.merge(password_confirmation: "different_password"))
        expect(user).not_to be_valid
      end
    end

    describe "birthday and gender" do
      it "is not valid without a birthday" do
        user = User.new(valid_attributes.merge(birthday: nil))
        expect(user).not_to be_valid
      end
      it "is not valid without a gender" do
        user = User.new(valid_attributes.merge(gender: nil))
        expect(user).not_to be_valid
      end
      it "is not valid with a birthday in the future" do
        user = User.new(valid_attributes.merge(birthday: Time.zone.today + 1.day))
        expect(user).not_to be_valid
      end
      it "is not valid with a birthday more than 100 years ago" do
        user = User.new(valid_attributes.merge(birthday: Time.zone.today.prev_year(Settings.user.hundred_years + 1)))
        expect(user).not_to be_valid
      end
    end
  end

  # Test Associations
  describe "associations" do
    let!(:user) { create(:user) }

    it "has many created courses" do
      expect(user.created_courses).to be_empty
    end
    it "nullifies created courses when destroyed" do
      course = create(:course, creator: user)
      user.destroy
      course.reload
      expect(course.created_by_id).to be_nil
    end
    it "has many created lessons" do
      expect(user.created_lessons).to be_empty
    end
    it "nullifies created lessons when destroyed" do
      lesson = create(:lesson, creator: user)
      user.destroy
      lesson.reload
      expect(lesson.created_by_id).to be_nil
    end
    it "destroys user_courses when destroyed" do
      user_course = create(:user_course, user: user)
      expect { user.destroy }.to change { UserCourse.count }.by(-1)
    end
    it "destroys user_lessons when destroyed" do
      user_lesson = create(:user_lesson, user: user)
      expect { user.destroy }.to change { UserLesson.count }.by(-1)
    end
    it "destroys user_words when destroyed" do
      user_word = create(:user_word, user: user)
      expect { user.destroy }.to change { UserWord.count }.by(-1)
    end
  end

  # Test Class methods
  describe "class methods" do
    it ".new_token returns a new token" do
      expect(User.new_token).to be_a(String)
    end
    it ".digest digests a string" do
      expect(User.digest("password")).to be_a(String)
    end
    it ".find_or_create_from_auth_hash finds an existing user" do
      existing_user = create(:user)
      auth_hash = OpenStruct.new(info: OpenStruct.new(email: existing_user.email, name: existing_user.name))
      expect { User.find_or_create_from_auth_hash(auth_hash) }.not_to change(User, :count)
    end
  end

  # Test Instance methods
  describe "instance methods" do
    let(:user) { create(:user) }

    it "#remember sets a remember_digest" do
      user.remember
      expect(user.remember_digest).not_to be_nil
    end

    it "#authenticated? returns true for correct token" do
      user.remember
      expect(user.authenticated?(user.remember_token)).to be_truthy
    end

    it "#authenticated? returns false for incorrect token" do
      user.remember
      expect(user.authenticated?("invalid_token")).to be_falsey
    end

    it "#forget sets remember_digest to nil" do
      user.remember
      user.forget
      expect(user.remember_digest).to be_nil
    end

    it "#oauth_user? returns true for oauth user" do
      user = create(:user, provider: "google", uid: "123")
      expect(user.oauth_user?).to be_truthy
    end
    it "#oauth_user? returns false for regular user" do
      expect(user.oauth_user?).to be_falsey
    end
  end
end
