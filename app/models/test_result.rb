class TestResult < ApplicationRecord
  belongs_to :user
  belongs_to :component

  enum status: {passed: 0, failed: 1}

  # Validations
  validates :attempt_number, presence: true
  validates :mark, presence: true
end
