class User::WordsController < User::ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource class: Word.name, only: %i(index)

  def index
    @learned_ids = Word.learned_word_ids_for(current_user)
    @pagy, @words = pagy(filtered_words, limit: Settings.page_20)
  end

  private

  def filtered_words
    Word.search(params[:search], params[:search_field])
        .filter_by_type(params[:word_type])
        .sorted(params[:sort])
        .filter_by_status(params[:status]&.to_sym, current_user)
  end
end
