class Test < ApplicationRecord
  IMAGE_DISPLAY_SIZE = [300, 200].freeze
  MINIMUM_DURATION = 0
  MINIMUM_NAME_LENGTH = 3
  MAX_NAME_LENGTH = 100
  MINIMUM_DESCRIPTION_LENGTH = 10
  MAX_DESCRIPTION_LENGTH = 500
  TEST_PERMITTED = %i(name description duration max_attempts).freeze

  has_many :questions, dependent: :destroy
  has_many :components, dependent: :destroy

  validates :name, :description, :duration, :max_attempts, presence: true
  validates :duration, :max_attempts,
            numericality: {greater_than: MINIMUM_DURATION}
  validates :name,
            length: {minimum: MINIMUM_NAME_LENGTH, maximum: MAX_NAME_LENGTH}
  validates :description,
            length: {minimum: MINIMUM_DESCRIPTION_LENGTH,
                     maximum: MAX_DESCRIPTION_LENGTH}

  accepts_nested_attributes_for :questions, allow_destroy: true

  scope :recent, ->{order(created_at: :desc)}
  scope :by_name, lambda {|keyword|
    return all if keyword.blank?

    where("name LIKE ?", "%#{sanitize_sql_like(keyword)}%")
  }

  def self.ransackable_attributes _auth_object = nil
    %w(name created_at updated_at)
  end
end
