class UserLesson < ApplicationRecord
  belongs_to :user
  belongs_to :lesson

  enum status: {incomplete: 0, completed: 1}

  scope :for_course, lambda {|course|
                       joins(:lesson)
                         .where(lessons: {course_id: course.id})
                     }
end
