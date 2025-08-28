module User::CoursesHelper
  def enrolment_status_options
    UserCourse.enrolment_statuses.map do |key, value|
      [I18n.t("user.courses.filter.#{key}", default: key.humanize), value]
    end
  end

  def learner_count_options
    [
      [I18n.t("user.courses.filter.rangeone"), "1-10"],
      [I18n.t("user.courses.filter.rangeeleven"), "11-20"],
      [I18n.t("user.courses.filter.rangetwentyfirst"), "21-30"],
      [I18n.t("user.courses.filter.rangeoverthirtyone"), "31+"]
    ]
  end
end
