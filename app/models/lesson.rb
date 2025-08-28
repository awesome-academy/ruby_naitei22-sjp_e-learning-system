class Lesson < ApplicationRecord
  belongs_to :course
  belongs_to :creator, class_name: User.name, foreign_key: "created_by_id"

  has_many :components, dependent: :destroy
  has_many :user_lessons, dependent: :destroy
  has_many :test_results, through: :components

  accepts_nested_attributes_for :components, allow_destroy: true

  # Validations
  validates :title, presence: true
  validates :description, presence: true
  validates :position, presence: true

  # Scopes
  scope :with_user_lessons_for, (lambda do |user|
    includes(:user_lessons).where(user_lessons: {user_id: [user.id, nil]})
  end)

  scope :by_position, ->{order(position: :asc)}

  scope :by_content, (lambda do |query|
    return all if query.blank?

    where("title LIKE ?", "%#{query}%")
  end)

  scope :by_time, lambda {|filter_time|
    case filter_time
    when Settings.filter_days.today
      where("created_at >= ?", Time.zone.now.beginning_of_day)
    when Settings.filter_days.last_7_days, Settings.filter_days.last_30_days
      days = Settings.word.filter_days[filter_time].to_i
      where("created_at >= ?", days.days.ago.beginning_of_day)
    else
      all
    end
  }

  LESSON_PERMITTED = [
    :title,
    :description,
    {word_ids: [],
     test_ids: [],
     paragraphs: [:content]}
  ].freeze
end
