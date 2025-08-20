require "rails_helper"

RSpec.describe Test, type: :model do
  around do |example|
    I18n.with_locale(:en){example.run}
  end

  describe "associations" do
    it "has many questions" do
      association = described_class.reflect_on_association(:questions)
      expect(association.macro).to eq(:has_many)
    end

    it "has many components" do
      association = described_class.reflect_on_association(:components)
      expect(association.macro).to eq(:has_many)
    end

    let(:test){create(:test)}

    it "returns the correct questions" do
      questions = create_list(:question, 2, test:)
      expect(test.questions).to contain_exactly(*questions)
    end

    it "returns the correct components" do
      lesson = create(:lesson)

      component1 = create(:component, lesson:, test:)
      component2 = create(:component, lesson:, test:)

      expect(test.components).to contain_exactly(component1, component2)
    end
  end

  describe "validations" do
    context "for presence" do
      context "when name is nil" do
        subject{build(:test, name: nil)}

        it "is not valid" do
          expect(subject).not_to be_valid
        end

        it "returns a 'blank' error message for name" do
          subject.valid?
          expect(subject.errors[:name]).to include(I18n.t("errors.messages.blank"))
        end
      end

      context "when description is nil" do
        subject{build(:test, description: nil)}

        it "is not valid" do
          expect(subject).not_to be_valid
        end

        it "returns a 'blank' error message for description" do
          subject.valid?
          expect(subject.errors[:description]).to include(I18n.t("errors.messages.blank"))
        end
      end

      context "when duration is nil" do
        subject{build(:test, duration: nil)}

        it "is not valid" do
          expect(subject).not_to be_valid
        end

        it "returns a blank error message for duration" do
          subject.valid?
          expect(subject.errors[:duration]).to include(I18n.t("errors.messages.blank"))
        end
      end

      context "when max_attempts is nil" do
        subject{build(:test, max_attempts: nil)}

        it "is not valid" do
          expect(subject).not_to be_valid
        end

        it "returns a blank error message for max_attempts" do
          subject.valid?
          expect(subject.errors[:max_attempts]).to include(I18n.t("errors.messages.blank"))
        end
      end
    end

    context "for numericality" do
      context "when duration is not greater than the minimum" do
        subject{build(:test, duration: Test::MINIMUM_DURATION)}

        it "is not valid" do
          expect(subject).not_to be_valid
        end

        it "returns a 'greater than' error message for duration" do
          subject.valid?
          expect(subject.errors[:duration]).to include("must be greater than #{Test::MINIMUM_DURATION}")
        end
      end
    end

    context "for length" do
      context "when the name is too short" do
        let(:short_name){"a" * (Test::MINIMUM_NAME_LENGTH - 1)}
        subject{build(:test, name: short_name)}

        it "is not valid" do
          expect(subject).not_to be_valid
        end

        it "returns a 'too short' error message for name" do
          subject.valid?
          expect(subject.errors[:name]).to include("is too short (minimum is #{Test::MINIMUM_NAME_LENGTH} characters)")
        end
      end

      context "when the name is too long" do
        let(:long_name){"a" * (Test::MAX_NAME_LENGTH + 1)}
        subject{build(:test, name: long_name)}

        it "is not valid" do
          expect(subject).not_to be_valid
        end

        it "returns a 'too long' error message for name" do
          subject.valid?
          expect(subject.errors[:name]).to include("is too long (maximum is #{Test::MAX_NAME_LENGTH} characters)")
        end
      end
    end
  end

  describe "nested attributes" do
    it "allows creating questions through nested_attributes" do
      test_attributes = attributes_for(:test).merge(
        questions_attributes: [{content: "What is Ruby?"}]
      )
      test = Test.new(test_attributes)
      expect(test.questions.size).to eq(1)
    end
  end

  describe "scopes" do
    let!(:test1){create(:test, name: "Ruby", created_at: 1.day.ago)}
    let!(:test2){create(:test, name: "Rails", created_at: Time.current)}

    context ".recent" do
      it "returns tests ordered by created_at descending" do
        expect(Test.recent).to eq([test2, test1])
      end
    end

    context ".by_name" do
      context "when keyword is blank" do
        it "returns all tests" do
          expect(Test.by_name("")).to match_array([test1, test2])
        end
      end

      context "when keyword is present" do
        let(:results){Test.by_name("Ruby")}

        it "includes the matching test" do
          expect(results).to include(test1)
        end

        it "does not include the non-matching test" do
          expect(results).not_to include(test2)
        end
      end
    end
  end

  describe "constants" do
    it "defines IMAGE_DISPLAY_SIZE" do
      expect(Test::IMAGE_DISPLAY_SIZE).to eq([300, 200])
    end

    it "defines TEST_PERMITTED" do
      expect(Test::TEST_PERMITTED).to include(:name, :description, :duration,
                                              :max_attempts)
    end
  end
end
