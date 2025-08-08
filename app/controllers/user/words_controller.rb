class User::WordsController < ApplicationController
  before_action :logged_in_user, :ensure_user_role, only: %i(index)

  def index
    base_query = filtered_words
    @learned_ids = Word.learned_word_ids_for(current_user)
    @pagy, @words = pagy(filter_by_status(base_query), limit: Settings.page_20)
  end

  private

  def filtered_words
    Word.search(params[:search], params[:search_field])
        .filter_by_type(params[:word_type])
        .sorted(params[:sort])
  end

  def filter_by_status base_query
    case params[:status]
    when "learned"
      base_query.where(id: @learned_ids)
    when "not_learned"
      base_query.where.not(id: @learned_ids)
    else
      base_query
    end
  end
end
