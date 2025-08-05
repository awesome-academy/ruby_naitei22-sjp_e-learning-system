# app/models/answer.rb
class Answer < ApplicationRecord
  belongs_to :question

  validates :content, presence: true

  after_initialize :set_default_correct, if: :new_record?

  private

  def set_default_correct
    self.correct = false if correct.nil?
  end
end
