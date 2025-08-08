module ApplicationHelper
  include Pagy::Frontend
  ZERO_TIME_FORMAT = "00:00".freeze
  def full_title page_title = ""
    base_title = t("layouts.application.title")
    page_title.empty? ? base_title : "#{page_title} | #{base_title}"
  end

  def render_breadcrumbs
    breadcrumbs = []
    breadcrumbs << link_to(content_tag(:i, "", class: "fas fa-home"),
                           root_path)

    safe_join(breadcrumbs,
              content_tag(:span, " > ", class: "breadcrumb-separator"))
  end

  def time_format seconds
    return ZERO_TIME_FORMAT if seconds <= 0

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60

    if hours.positive?
      format("%<hours>d:%<minutes>02d:%<secs>02d",
             hours:, minutes:, secs:)
    else
      format("%<minutes>02d:%<secs>02d",
             minutes:, secs:)
    end
  end
end
