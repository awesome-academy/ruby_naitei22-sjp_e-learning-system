require "rails_helper"

RSpec.describe Question, type: :model do
  # Test Validations
  describe "validations" do
    let(:test) { create(:test) }

    it "is valid with content, question_type, and at least one correct answer" do
      question = Question.new(
        content: "Valid question content",
        question_type: :single_choice,
        test: test,
        answers_attributes: [
          { content: "Correct answer", correct: true }
        ]
      )
      expect(question).to be_valid
    end

    it "is not valid without content" do
      question = Question.new(content: nil, question_type: :single_choice, test: test)
      expect(question).not_to be_valid
    end

    it "is not valid without question_type" do
      question = Question.new(content: "Question content", question_type: nil, test: test)
      expect(question).not_to be_valid
    end

    it "is not valid without at least one correct answer" do
      question = Question.new(
        content: "Question content",
        question_type: :single_choice,
        test: test,
        answers_attributes: [
          { content: "Incorrect answer", correct: false }
        ]
      )
      expect(question).not_to be_valid
    end

    it "includes a base error when there is no correct answer" do
      question = Question.new(
        content: "Question content",
        question_type: :single_choice,
        test: test,
        answers_attributes: [
          { content: "Incorrect answer", correct: false }
        ]
      )
      question.valid?
      expect(question.errors[:base]).to include(
        I18n.t("admin.questions.at_least_one_correct_answer_required")
      )
    end
  end
end
