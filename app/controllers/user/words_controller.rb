class User::WordsController < User::ApplicationController
  load_and_authorize_resource

  def index
    @learned_ids = Word.learned_word_ids_for(current_user)
    ransack_params = build_ransack_params
    @q = Word.ransack(ransack_params)
    words = @q.result(distinct: true)
              .filter_by_status(params[:status]&.to_sym, current_user)

    @pagy, @words = pagy(words, limit: Settings.page_20)
  end

  private

  def build_ransack_params
    q_params = params[:q] || {}
    return q_params if params[:keyword].blank?

    search_key = case params[:search_field]
                 when "content"
                   :content_cont
                 when "meaning"
                   :meaning_cont
                 else
                   :content_or_meaning_cont
                 end
    q_params[search_key] = params[:keyword]
    q_params
  end
end
