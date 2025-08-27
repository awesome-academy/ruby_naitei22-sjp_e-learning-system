require "rails_helper"

RSpec.describe Test, type: :model do
  # Test Validations
  describe "validations" do
    let(:valid_attributes) do
      {
        name: "Test Name",
        description: "A valid description for the test.",
        duration: 60,
        max_attempts: 3
      }
    end

    it "is valid with all valid attributes" do
      test = Test.new(valid_attributes)
      expect(test).to be_valid
    end

    it "is not valid without a name" do
      test = Test.new(valid_attributes.merge(name: nil))
      expect(test).not_to be_valid
    end

    it "is not valid without a description" do
      test = Test.new(valid_attributes.merge(description: nil))
      expect(test).not_to be_valid
    end

    it "is not valid without a duration" do
      test = Test.new(valid_attributes.merge(duration: nil))
      expect(test).not_to be_valid
    end

    it "is not valid without max_attempts" do
      test = Test.new(valid_attributes.merge(max_attempts: nil))
      expect(test).not_to be_valid
    end

    it "is not valid with a name shorter than minimum length" do
      test = Test.new(valid_attributes.merge(name: "ab"))
      expect(test).not_to be_valid
    end

    it "is not valid with a name longer than maximum length" do
      test = Test.new(valid_attributes.merge(name: "a" * (Test::MAX_NAME_LENGTH + 1)))
      expect(test).not_to be_valid
    end

    it "is not valid with a duration less than or equal to 0" do
      test = Test.new(valid_attributes.merge(duration: 0))
      expect(test).not_to be_valid
    end

    it "is not valid with max_attempts less than or equal to 0" do
      test = Test.new(valid_attributes.merge(max_attempts: 0))
      expect(test).not_to be_valid
    end
  end

  # Test Scopes
  describe "scopes" do
    let!(:test1) { create(:test, name: "Test A", created_at: 2.days.ago) }
    let!(:test2) { create(:test, name: "Test B", created_at: 1.day.ago) }
    let!(:test3) { create(:test, name: "Another Test", created_at: 3.days.ago) }

    describe ".recent" do
      it "returns tests in descending order of creation date" do
        expect(Test.recent).to eq([test2, test1, test3])
      end
    end

    describe ".by_name" do
      context "with a valid keyword" do
        it "returns tests whose name includes the keyword" do
          expect(Test.by_name("Test A")).to match_array([test1])
        end
      end

      context "with a blank keyword" do
        it "returns all tests" do
          expect(Test.by_name(nil)).to match_array([test1, test2, test3])
        end
      end
    end
  end
end
