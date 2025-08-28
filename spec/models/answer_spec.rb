require "rails_helper"

RSpec.describe Answer, type: :model do
  let!(:question) { create(:question) }

  # Test Validations
  describe "validations" do
    let(:valid_attributes) { { content: "Sample answer", question: question } }

    it "is valid with a content" do
      answer = Answer.new(valid_attributes)
      expect(answer).to be_valid
    end

    it "is not valid without content" do
      answer = Answer.new(valid_attributes.merge(content: nil))
      expect(answer).not_to be_valid
    end
  end

  # Test Callbacks
  describe "callbacks" do
    describe "#set_default_correct" do
      context "when a new record is created" do
        it "sets correct to false if it is nil" do
          answer = Answer.new(content: "Test content", question: question)
          expect(answer.correct).to be_falsey
        end
        it "does not change correct if it is already set" do
          answer = Answer.new(content: "Test content", correct: true, question: question)
          expect(answer.correct).to be_truthy
        end
      end

      context "when an existing record is updated" do
        let!(:existing_answer) { create(:answer, correct: true, question: question) }

        it "does not change correct when it is updated" do
          existing_answer.correct = false
          existing_answer.save!
          expect(existing_answer.correct).to be_falsey
        end
      end
    end
  end
end
