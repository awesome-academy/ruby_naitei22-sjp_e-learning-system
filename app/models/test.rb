class Test < ApplicationRecord
  has_many :questions, dependent: :destroy
  has_many :components, dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true
  validates :duration, presence: true, numericality: {greater_than: 0}
  validates :max_attempts, presence: true,
numericality: {greater_than_or_equal_to: 0}

  accepts_nested_attributes_for :questions, allow_destroy: true

  scope :newest, ->{order(created_at: :desc)}
end
