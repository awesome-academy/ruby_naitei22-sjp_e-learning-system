module User::WordsHelper
  def search_field_options
    [
      [t(".search_fields.all"), :all],
      [t(".search_fields.content"), :content],
      [t(".search_fields.meaning"), :meaning]
    ]
  end

  def status_options
    [
      [t(".status_all"), :all],
      [t(".status_learned"), :learned],
      [t(".status_not_learned"), :not_learned]
    ]
  end

  def word_type_options
    Word.word_types.keys.map{|k| [t(".word_types.#{k}"), k]}
  end

  def sort_options
    [
      [t(".sort_options.alphabetical"), "content asc"],
      [t(".sort_options.alphabetical_desc"), "content desc"],
      [t(".sort_options.newest"), "created_at desc"],
      [t(".sort_options.oldest"), "created_at asc"],
      [t(".sort_options.word_type"), "word_type_key asc, content asc"]
    ]
  end

  def badge_class word_type
    case word_type.to_sym
    when :noun      then "label-primary"
    when :verb      then "label-info"
    when :adjective then "label-success"
    when :adverb    then "label-warning"
    else "label-default"
    end
  end

  def search_input_value params
    params.dig(:q, :content_cont) ||
      params.dig(:q, :meaning_cont) ||
      params.dig(:q, :content_or_meaning_cont)
  end

  def selected_search_field params
    return "all" if params[:q].blank?

    if params[:q].key?(:content_cont)
      "content"
    elsif params[:q].key?(:meaning_cont)
      "meaning"
    else
      "all"
    end
  end
end
