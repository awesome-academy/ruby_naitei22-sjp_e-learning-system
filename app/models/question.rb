class Question < ApplicationRecord
  belongs_to :test
  has_many :answers, dependent: :destroy

  enum question_type: {single_choice: 0, multiple_choice: 1}

  accepts_nested_attributes_for :answers, allow_destroy: true

  validates :content, :question_type, presence: true
end
