class UserCourse < ApplicationRecord
  belongs_to :user
  belongs_to :course

  enum enrolment_status: {
    pending: 0,
    approved: 1,
    rejected: 2,
    in_progress: 3,
    completed: 4
  }

  ASSOCIATIONS = %i(user course).freeze

  ENROLMENT_STATUSES = [
    enrolment_statuses[:approved],
    enrolment_statuses[:in_progress],
    enrolment_statuses[:completed]
  ].freeze

  COURSE_INCLUDES = {
    course: [
      :approved_user_courses,
      {thumbnail_attachment: :blob}
    ]
  }.freeze

  APPROVABLE_STATUSES = %i(pending rejected).freeze
  REJECTABLE_STATUSES = %i(pending approved).freeze

  INVALID_APPROVE_STATUSES = %i(approved in_progress).freeze
  INVALID_REJECT_STATUSES = %i(rejected in_progress).freeze

  scope :approved_statuses, ->{where(enrolment_status: ENROLMENT_STATUSES)}

  scope :with_course, ->{includes(COURSE_INCLUDES)}

  scope :with_status_in, (lambda do |status|
    status.present? ? where(enrolment_status: status) : all
  end)

  scope :recent, ->{order(created_at: :desc)}

  scope :by_course, (lambda do |course_id|
    where(course_id:) if course_id.present?
  end)

  scope :by_status, (lambda do |status|
    where(enrolment_status: status) if status.present?
  end)

  scope :registered_from, (lambda do |date|
    where("created_at >= ?", date) if date.present?
  end)

  scope :expiration_date, (lambda do |date|
    where("created_at <= ?", date) if date.present?
  end)

  scope :approvable, ->{with_status_in(APPROVABLE_STATUSES)}
  scope :rejectable, ->{with_status_in(REJECTABLE_STATUSES)}

  scope :invalid_for_approve, ->{with_status_in(INVALID_APPROVE_STATUSES)}
  scope :invalid_for_reject, ->{with_status_in(INVALID_REJECT_STATUSES)}

  validates :reason, presence: true, if: ->{rejected?}

  def self.ransackable_attributes _auth_object = nil
    %w(user_id course_id enrolment_status created_at end_date start_date)
  end

  def self.ransackable_associations _auth_object = nil
    %w(course user)
  end
end
