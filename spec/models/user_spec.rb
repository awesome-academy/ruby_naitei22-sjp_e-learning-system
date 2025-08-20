# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { build(:user) }
  let(:oauth_user) { build(:user, :oauth) }
  let!(:another_user) { create(:user) }

  it "is valid with a complete factory" do
    expect(build(:user)).to be_valid
  end

  # ---
  # Validations
  # ---
  describe "#name" do
    it "is not valid when name is blank" do
      user.name = ""
      expect(user).not_to be_valid
    end

    it "adds blank error when name is blank" do
      user.name = ""
      user.valid?
      expect(user.errors[:name]).to include(I18n.t("errors.messages.blank"))
    end

    it "is valid when name length is within max length" do
      user.name = "a" * Settings.user.max_name_length
      expect(user).to be_valid
    end

    it "is not valid when name length exceeds max length" do
      user.name = "a" * (Settings.user.max_name_length + 1)
      expect(user).not_to be_valid
    end

    it "adds too_long error when name length exceeds max length" do
      user.name = "a" * (Settings.user.max_name_length + 1)
      user.valid?
      expect(user.errors[:name]).to include(
        I18n.t("errors.messages.too_long", count: Settings.user.max_name_length)
      )
    end
  end

  describe "#email" do
    it "is not valid when email is blank" do
      user.email = ""
      expect(user).not_to be_valid
    end

    it "adds blank error when email is blank" do
      user.email = ""
      user.valid?
      expect(user.errors[:email]).to include(I18n.t("errors.messages.blank"))
    end

    it "is not valid when email exceeds max length" do
      user.email = "a" * (Settings.user.max_email_length) + "@ex.com"
      expect(user).not_to be_valid
    end

    it "adds too_long error when email exceeds max length" do
      user.email = "a" * (Settings.user.max_email_length) + "@ex.com"
      user.valid?
      expect(user.errors[:email]).to include(
        I18n.t("errors.messages.too_long", count: Settings.user.max_email_length)
      )
    end

    it "is not valid when email is duplicated" do
      user.email = another_user.email
      expect(user).not_to be_valid
    end

    it "adds taken error when email is duplicated" do
      user.email = another_user.email
      user.valid?
      expect(user.errors[:email]).to include(I18n.t("errors.messages.taken"))
    end

    it "is not valid with malformed email" do
      user.email = "invalid-email"
      expect(user).not_to be_valid
    end

    it "adds invalid error with malformed email" do
      user.email = "invalid-email"
      user.valid?
      expect(user.errors[:email]).to include(I18n.t("errors.messages.invalid"))
    end

    it "is valid with proper email format" do
      user.email = "test@example.com"
      expect(user).to be_valid
    end
  end

  describe "#birthday" do
    context "when it's a normal user" do
      it "is not valid when birthday is blank" do
        user.birthday = nil
        expect(user).not_to be_valid
      end

      it "adds blank error when birthday is blank" do
        user.birthday = nil
        user.valid?
        expect(user.errors[:birthday]).to include(I18n.t("errors.messages.blank"))
      end

      it "is not valid when too old (> 100 years)" do
        user.birthday = 101.years.ago.to_date
        expect(user).not_to be_valid
      end

      it "adds too_old error when birthday is too old" do
        user.birthday = 101.years.ago.to_date
        user.valid?
        expect(user.errors[:birthday]).to include(
          I18n.t("activerecord.errors.models.user.attributes.birthday.too_old")
        )
      end

      it "is not valid when birthday is in the future" do
        user.birthday = 1.day.from_now.to_date
        expect(user).not_to be_valid
      end

      it "adds in_future error when birthday is in the future" do
        user.birthday = 1.day.from_now.to_date
        user.valid?
        expect(user.errors[:birthday]).to include(
          I18n.t("activerecord.errors.models.user.attributes.birthday.in_future")
        )
      end
    end

    context "when it's an OAuth user" do
      it "is valid without birthday" do
        oauth_user.birthday = nil
        expect(oauth_user).to be_valid
      end
    end
  end

  describe "#gender" do
    context "when it's a normal user" do
      it "is not valid when gender is blank" do
        user.gender = nil
        expect(user).not_to be_valid
      end

      it "adds blank error when gender is blank" do
        user.gender = nil
        user.valid?
        expect(user.errors[:gender]).to include(I18n.t("errors.messages.blank"))
      end
    end

    context "when it's an OAuth user" do
      it "is valid without gender" do
        oauth_user.gender = nil
        expect(oauth_user).to be_valid
      end
    end
  end

  describe "#password_presence_if_confirmation_provided" do
    let(:user) { build(:user, password: nil, password_confirmation: "some_password") }

    it "is not valid when password is blank but confirmation is present" do
      expect(user).not_to be_valid
    end

    it "adds error message when password is blank but confirmation is present" do
      user.valid?
      expect(user.errors[:password]).to include(
        I18n.t("activerecord.errors.models.user.attributes.password.password_blank")
      )
    end
  end

  # ---
  # Associations
  # ---
  describe "Associations" do
    # created_courses
    it "has many created_courses" do
      assoc = described_class.reflect_on_association(:created_courses)
      expect(assoc.macro).to eq :has_many
    end

    it "uses Course class for created_courses" do
      assoc = described_class.reflect_on_association(:created_courses)
      expect(assoc.options[:class_name]).to eq "Course"
    end

    it "uses created_by_id as foreign key for created_courses" do
      assoc = described_class.reflect_on_association(:created_courses)
      expect(assoc.options[:foreign_key]).to eq "created_by_id"
    end

    it "returns the correct created_courses" do
      user = create(:user)
      course1 = create(:course, created_by_id: user.id)
      course2 = create(:course, created_by_id: user.id)
      expect(user.created_courses).to contain_exactly(course1, course2)
    end

    # created_lessons
    it "has many created_lessons" do
      assoc = described_class.reflect_on_association(:created_lessons)
      expect(assoc.macro).to eq :has_many
    end

    it "uses Lesson class for created_lessons" do
      assoc = described_class.reflect_on_association(:created_lessons)
      expect(assoc.options[:class_name]).to eq "Lesson"
    end

    it "uses created_by_id as foreign key for created_lessons" do
      assoc = described_class.reflect_on_association(:created_lessons)
      expect(assoc.options[:foreign_key]).to eq "created_by_id"
    end

    it "returns the correct created_lessons" do
      user = create(:user)
      lesson1 = create(:lesson, created_by_id: user.id)
      lesson2 = create(:lesson, created_by_id: user.id)
      expect(user.created_lessons).to contain_exactly(lesson1, lesson2)
    end

    # user_courses + enrolled_courses
    it "has many user_courses" do
      assoc = described_class.reflect_on_association(:user_courses)
      expect(assoc.macro).to eq :has_many
    end

    it "returns the correct user_courses" do
      user = create(:user)
      course = create(:course)
      user_course = create(:user_course, user:, course:)
      expect(user.user_courses).to include(user_course)
    end

    it "has many enrolled_courses through user_courses" do
      assoc = described_class.reflect_on_association(:enrolled_courses)
      expect(assoc.macro).to eq :has_many
    end

    it "uses user_courses as through for enrolled_courses" do
      assoc = described_class.reflect_on_association(:enrolled_courses)
      expect(assoc.options[:through]).to eq :user_courses
    end

    it "returns the correct enrolled_courses" do
      user = create(:user)
      course1 = create(:course)
      course2 = create(:course)
      create(:user_course, user:, course: course1)
      create(:user_course, user:, course: course2)
      expect(user.enrolled_courses).to contain_exactly(course1, course2)
    end

    # user_lessons + lessons
    it "has many user_lessons" do
      assoc = described_class.reflect_on_association(:user_lessons)
      expect(assoc.macro).to eq :has_many
    end

    it "returns the correct user_lessons" do
      user = create(:user)
      lesson = create(:lesson)
      user_lesson = create(:user_lesson, user:, lesson:)
      expect(user.user_lessons).to include(user_lesson)
    end

    it "has many lessons through user_lessons" do
      assoc = described_class.reflect_on_association(:lessons)
      expect(assoc.macro).to eq :has_many
    end

    it "uses user_lessons as through for lessons" do
      assoc = described_class.reflect_on_association(:lessons)
      expect(assoc.options[:through]).to eq :user_lessons
    end

    it "returns the correct lessons" do
      user = create(:user)
      lesson1 = create(:lesson)
      lesson2 = create(:lesson)
      create(:user_lesson, user:, lesson: lesson1)
      create(:user_lesson, user:, lesson: lesson2)
      expect(user.lessons).to contain_exactly(lesson1, lesson2)
    end

    # admin_course_managers + managed_courses
    it "has many admin_course_managers" do
      assoc = described_class.reflect_on_association(:admin_course_managers)
      expect(assoc.macro).to eq :has_many
    end

    it "returns the correct admin_course_managers" do
      user = create(:user)
      course = create(:course)
      acm = create(:admin_course_manager, user:, course:)
      expect(user.admin_course_managers).to include(acm)
    end

    it "has many managed_courses through admin_course_managers" do
      assoc = described_class.reflect_on_association(:managed_courses)
      expect(assoc.macro).to eq :has_many
    end

    it "uses admin_course_managers as through for managed_courses" do
      assoc = described_class.reflect_on_association(:managed_courses)
      expect(assoc.options[:through]).to eq :admin_course_managers
    end

    it "returns the correct managed_courses" do
      user = create(:user)
      course1 = create(:course)
      course2 = create(:course)
      create(:admin_course_manager, user:, course: course1)
      create(:admin_course_manager, user:, course: course2)
      expect(user.managed_courses).to contain_exactly(course1, course2)
    end

    # user_words
    it "has many user_words" do
      assoc = described_class.reflect_on_association(:user_words)
      expect(assoc.macro).to eq :has_many
    end

    it "returns the correct user_words" do
      user = create(:user)
      component = create(:component)
      user_word = create(:user_word, user:, component:)
      expect(user.user_words).to include(user_word)
    end

    # test_results
    it "has many test_results" do
      assoc = described_class.reflect_on_association(:test_results)
      expect(assoc.macro).to eq :has_many
    end

    it "returns the correct test_results" do
      user = create(:user)
      test_result = create(:test_result, user:)
      expect(user.test_results).to include(test_result)
    end
  end

  # ---
  # Enums
  # ---
  describe "Enums" do
    it "defines gender enum values" do
      expect(User.genders).to eq("male" => 0, "female" => 1, "other" => 2)
    end

    it "defines role enum values" do
      expect(User.roles).to eq("user" => 0, "admin" => 1)
    end
  end

  # ---
  # Methods
  # ---
  describe "Instance methods" do
    describe "#authenticated?" do
      context "when the remember digest is valid" do
        it "returns true" do
          user.remember
          expect(user.authenticated?(user.remember_token)).to be true
        end
      end

      context "when the remember digest is nil" do
        it "returns false" do
          user.remember_digest = nil
          expect(user.authenticated?("some_token")).to be false
        end
      end
    end

    describe "#forget" do
      it "clears the remember_digest" do
        user.remember
        user.forget
        expect(user.remember_digest).to be_nil
      end
    end

    describe "#oauth_user?" do
      it "returns true when provider and uid are present" do
        expect(oauth_user.oauth_user?).to be true
      end

      it "returns false when provider is missing" do
        expect(user.oauth_user?).to be false
      end
    end
  end

  describe "Class methods" do
    describe ".digest" do
      let(:string) { "example_password" }

      it "returns a BCrypt hash of the string" do
        digest = User.digest(string)
        expect(BCrypt::Password.new(digest)).to eq string
      end

      it "returns a valid BCrypt hash when min_cost is false" do
        original_min_cost = ActiveModel::SecurePassword.min_cost
        ActiveModel::SecurePassword.min_cost = false

        digest = User.digest("example_password")
        expect(BCrypt::Password.new(digest)).to eq "example_password"

        ActiveModel::SecurePassword.min_cost = original_min_cost
      end
    end

    describe ".find_or_create_from_auth_hash" do
      let(:auth) do
        OmniAuth::AuthHash.new({
          provider: "google_oauth2",
          uid: "12345",
          info: {
            name: "Test User",
            email: "testuser@example.com"
          }
        })
      end

      context "when user already exists" do
        before { create(:user, email: auth.info.email) }

        it "does not create a new user" do
          expect { User.find_or_create_from_auth_hash(auth) }.not_to change(User, :count)
        end

        it "updates provider if not present" do
          found_user = User.find_or_create_from_auth_hash(auth)
          expect(found_user.provider).to eq("google_oauth2")
        end

        it "updates uid if not present" do
          found_user = User.find_or_create_from_auth_hash(auth)
          expect(found_user.uid).to eq("12345")
        end
      end

      context "when user does not exist" do
        it "creates a new user" do
          expect { User.find_or_create_from_auth_hash(auth) }.to change(User, :count).by(1)
        end
      end
    end
  end
end
