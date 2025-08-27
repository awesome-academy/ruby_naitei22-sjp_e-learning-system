class Course < ApplicationRecord
  IMAGE_DISPLAY_SIZE = [300, 200].freeze
  DESCRIPTION_PREVIEW_LENGTH = 100
  ENROLLEE_BUCKETS = {
    "1-10" => (1..10),
    "11-20" => (11..20),
    "21-30" => (10..30),
    "31+" => (31..Float::INFINITY)
  }.freeze

  attr_accessor :course_admin_ids

  belongs_to :creator, class_name: User.name, foreign_key: "created_by_id"

  after_save :assign_admin_managers_from_ids, if: ->{course_admin_ids.present?}

  MINIMUM_DURATION = 0
  MINIMUM_TITLE_LENGTH = 5
  MAX_TITLE_LENGTH = 100

  COURSE_PERMITTED = [
    :title, :description, :duration,
    {course_admin_ids: []},
    {lessons_attributes: %i(id title content _destroy)}
  ].freeze
  COURSE_PRELOAD = [:creator, :lessons, :admins].freeze
  COURSE_INCLUDES = [:lessons, :admins, :users].freeze

  has_many :lessons, dependent: :destroy
  has_many :user_courses, dependent: :destroy
  has_many :users, through: :user_courses
  has_many :admin_course_managers, dependent: :destroy
  has_many :admins, through: :admin_course_managers, source: :user

  has_many :approved_user_courses,
           ->{approved_statuses},
           class_name: UserCourse.name,
           dependent: :destroy

  has_one_attached :thumbnail

  scope :recent, ->{order(created_at: :desc)}
  scope :with_users, ->{includes(:approved_user_courses)}
  scope :by_title, lambda {|title|
    return all if title.blank?

    where("title LIKE ?", "%#{title}%")
  }

  scope :search_name, (lambda do |keyword|
    return all if keyword.blank?

    where("title LIKE ?", "%#{keyword}%")
  end)

  scope :with_status_for_user, (lambda do |status, user|
    return all unless user && status.present?

    case status
    when :not_enrolled
      where.not(id: UserCourse.select(:course_id).where(user_id: user.id))
    else
      joins(:user_courses)
        .where(user_courses: {user_id: user.id})
        .merge(UserCourse.with_status_in(status))
    end
  end)

  scope :with_enrollee_bucket, (lambda do |bucket|
    return all if bucket.blank?

    range = ENROLLEE_BUCKETS[bucket]
    return all unless range

    subq = UserCourse.approved_statuses
                     .select("user_courses.course_id, COUNT(*) AS enroll_count")
                     .group("user_courses.course_id")

    rel = joins("LEFT JOIN (#{subq.to_sql}) uc_counts
    ON uc_counts.course_id = courses.id")

    if range.end.infinite?
      rel.where("COALESCE(uc_counts.enroll_count, 0) >= ?", range.begin)
    else
      rel.where("COALESCE(uc_counts.enroll_count, 0) BETWEEN ? AND ?",
                range.begin, range.end)
    end
  end)

  validates :title, presence: true,
length: {minimum: MINIMUM_TITLE_LENGTH, maximum: MAX_TITLE_LENGTH},
uniqueness: true
  validates :description, presence: true
  validates :duration, presence: true,
numericality: {greater_than: MINIMUM_DURATION}

  accepts_nested_attributes_for :admin_course_managers, :lessons,
                                allow_destroy: true

  def progress_percentage_for_user user
    course_lessons = lessons.includes(:user_lessons)
    total = course_lessons.count

    return 0 if total.zero?

    completed = UserLesson.count_for_user_and_lessons(user,
                                                      course_lessons.pluck(:id))
    percentage = completed.to_f / total * 100
    percentage.round
  end

  def self.ransackable_attributes _auth = nil
    %w(title description duration created_at updated_at)
  end

  def self.ransackable_associations _ = nil
    %w(approved_user_courses)
  end

  def self.ransackable_scopes _ = nil
    %i(with_enrollee_bucket)
  end

  private

  def assign_admin_managers_from_ids
    assign_admin_managers(course_admin_ids)
  end

  def assign_admin_managers admin_ids
    return if admin_ids.blank?

    admin_course_managers.destroy_all

    admin_ids.compact_blank.uniq.each do |admin_id|
      manager = admin_course_managers.create(user_id: admin_id)

      unless manager.persisted?
        errors.add(t(".assign_admin_failed", admin_id:, course_id: id))
        raise ActiveRecord::Rollback
      end
    end
  end
end
