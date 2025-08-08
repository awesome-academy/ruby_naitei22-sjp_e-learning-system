class TestResult < ApplicationRecord
  belongs_to :user
  belongs_to :component

  enum status: {passed: 0, failed: 1}

  # Validations
  validates :attempt_number, presence: true
  validates :mark, presence: true
  validates :user_answers, presence: true

  # Scope for getting latest attempt
  scope :latest_attempt, ->{order(attempt_number: :desc).limit(1)}

  # Instance methods
  def passed?
    status == "passed"
  end

  def failed?
    status == "failed"
  end

  def score_percentage
    mark
  end

  def total_questions
    user_answers.keys.count
  end

  def correct_answers_count
    user_answers.values.count{|answer| answer["is_correct"]}
  end

  def accuracy
    return 0 if total_questions.zero?

    (correct_answers_count.to_f / total_questions * 100).round(2)
  end
end
