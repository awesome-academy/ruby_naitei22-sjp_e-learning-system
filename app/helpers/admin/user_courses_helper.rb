module Admin::UserCoursesHelper
  def status_badge status
    case status.to_sym
    when :pending
      content_tag :span, t("helpers.admin.user_courses.status.pending"),
                  class: "badge bg-warning text-dark"
    when :approved
      content_tag :span, t("helpers.admin.user_courses.status.approved"),
                  class: "badge bg-success"
    when :rejected
      content_tag :span, t("helpers.admin.user_courses.status.rejected"),
                  class: "badge bg-danger"
    when :in_progress
      content_tag :span, t("helpers.admin.user_courses.status.in_progress"),
                  class: "badge bg-info text-white"
    when :completed
      content_tag :span, t("helpers.admin.user_courses.status.completed"),
                  class: "badge bg-primary"
    else
      content_tag :span, status.to_s.humanize, class: "badge bg-secondary"
    end
  end

  def status_filter_options
    [
      [t("admin.user_courses.index.status_options.pending"), :pending],
      [t("admin.user_courses.index.status_options.approved"), :approved],
      [t("admin.user_courses.index.status_options.rejected"), :rejected],
      [t("admin.user_courses.index.status_options.in_progress"), :in_progress],
      [t("admin.user_courses.index.status_options.completed"), :completed]
    ]
  end

  def course_filter_options
    [[t("admin.user_courses.index.status_options.all"), ""]] +
      Course.pluck(:title, :id)
  end

  # Progress circle calculations for SVG
  def progress_circle_radius
    45
  end

  def progress_circle_circumference radius = progress_circle_radius
    2 * Math::PI * radius
  end

  def progress_circle_dashoffset percentage, radius = progress_circle_radius
    c = progress_circle_circumference(radius)
    pct = (percentage || 0).to_f.clamp(0, 100)
    c * (1 - (pct / 100.0))
  end

  def progress_percentage_value percentage
    (percentage || 0).to_f.clamp(0, 100).to_i
  end
end
