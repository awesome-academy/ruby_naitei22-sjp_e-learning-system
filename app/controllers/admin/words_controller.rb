class Admin::WordsController < Admin::ApplicationController
  before_action :set_word, only: %i(edit update destroy)

  WORD_PERMITTED = %i(content meaning word_type).freeze

  # GET /admin/words
  def index
    @words = Word.by_content(params[:query])
                 .by_time(params[:filter_time])
                 .recent
    @pagy, @words = pagy(@words, items: Settings.word.pagy_items)
  end

  # GET /admin/words/new
  def new
    @word = Word.new
  end

  # POST /admin/words
  def create
    @word = Word.new(word_params)

    if @word.save
      flash[:success] = t(".success")
      redirect_to admin_words_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  # PATCH/PUT /admin/words/:id
  def update
    if @word.update(word_params)
      flash[:success] = t(".success")
      redirect_to admin_words_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/words/:id
  def destroy
    word_content = @word.content
    if @word.destroy
      flash[:success] = t(".success", word_content:)
    else
      flash[:danger] = t(".failure", word_content:)
    end
    redirect_to admin_words_path
  end

  private

  def set_word
    @word = Word.find_by(id: params[:id])
    return if @word

    flash[:danger] = t("not_found")
    redirect_to admin_words_path
  end

  def word_params
    params.require(:word).permit(WORD_PERMITTED)
  end
end
