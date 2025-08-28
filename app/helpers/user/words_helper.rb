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

  def filter_sort_options
    [
      [t("user.words.filter.sort_options.alphabetical"), "content asc"],
      [t("user.words.filter.sort_options.alphabetical_desc"), "content desc"],
      [t("user.words.filter.sort_options.newest"), "created_at desc"],
      [t("user.words.filter.sort_options.oldest"), "created_at asc"]
    ]
  end

  def word_type_options
    options = Word.word_types.map do |key, value|
      [I18n.t("user.words.filter.word_types.#{key}"), value]
    end

    options.unshift([I18n.t("user.words.filter.all_word_types"), ""])
  end

  def sort_options
    [
      [t(".sort_options.alphabetical"), :alphabetical],
      [t(".sort_options.alphabetical_desc"), :alphabetical_desc],
      [t(".sort_options.newest"), :newest],
      [t(".sort_options.oldest"), :oldest],
      [t(".sort_options.word_type"), :word_type]
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
end
