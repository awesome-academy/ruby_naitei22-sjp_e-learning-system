module ApplicationHelper
  include Pagy::Frontend

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
end
