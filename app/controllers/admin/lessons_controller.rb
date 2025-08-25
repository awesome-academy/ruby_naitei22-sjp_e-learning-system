class Admin::LessonsController < AdminController
  load_and_authorize_resource :course
  load_and_authorize_resource :lesson, through: :course

  LESSON_PERMITTED = [
    :title,
    :description,
    {word_ids: [],
     test_ids: [],
     paragraphs: [:content]}
  ].freeze

  # GET /admin/courses/:course_id/lessons/new
  def new
    @selected_word_ids = []
    @selected_test_ids = []
    @selected_paragraphs = []
  end

  # POST /admin/courses/:course_id/lessons
  def create
    @lesson = build_new_lesson
    components_params = params.require(:lesson)

    components_data = consolidate_components_data(components_params)

    ActiveRecord::Base.transaction do
      @lesson.save!

      @lesson.components.each(&:destroy!)

      new_components = build_component_attributes(@lesson, components_data)

      Component.insert_all!(new_components) if new_components.present?
    end

    flash[:success] = t(".success")
    redirect_to admin_course_lesson_path(@course, @lesson)
  rescue ActiveRecord::RecordInvalid => e
    @error_object = e.record
    render_error_for_form(:new, components_params)
  end

  # GET /admin/courses/:course_id/lessons/:id/edit
  def edit
    @selected_word_ids = @lesson.components.word.order(:index_in_lesson)
                                .pluck(:word_id)
    @selected_test_ids = @lesson.components.test.order(:index_in_lesson)
                                .pluck(:test_id)
    @selected_paragraphs = @lesson.components.paragraph.order(:index_in_lesson)
                                  .pluck(:content)
  end

  # PATCH/PUT /admin/courses/:course_id/lessons/:id
  def update
    components_params = params.require(:lesson)

    components_data = consolidate_components_data(components_params)

    ActiveRecord::Base.transaction do
      @lesson.update!(lesson_params.except(:word_ids, :test_ids, :paragraphs))

      @lesson.components.each(&:destroy!)

      new_components = build_component_attributes(@lesson, components_data)

      Component.insert_all!(new_components) if new_components.present?
    end

    flash[:success] = t(".success")
    redirect_to admin_course_lesson_path(@course, @lesson)
  rescue ActiveRecord::RecordInvalid => e
    @error_object = e.record
  end

  # GET /admin/courses/:course_id/lessons
  def index
    @lessons = @course.lessons.order(position: :asc)
    @lessons = @lessons.by_content(params[:query]) if params[:query].present?
    if params[:filter_time].present?
      @lessons = @lessons.by_time(params[:filter_time])
    end
    @pagy, @lessons = pagy(@lessons, items: Settings.lesson.pagy_items)
  end

  # GET /admin/courses/:course_id/lessons/:id
  def show; end

  # DELETE /admin/courses/:course_id/lessons/:id
  def destroy
    if @lesson.destroy
      flash[:success] = t(".success")
    else
      flash[:danger] = t(".failure")
    end
    redirect_to admin_course_lessons_path(@course)
  end

  private

  def render_error_for_form action, components_params,
    flash_message = t(".failure")
    @selected_word_ids = (components_params[:word_ids] || []).compact_blank
                                                             .map(&:to_i)
    @selected_test_ids = (components_params[:test_ids] || []).compact_blank
                                                             .map(&:to_i)
    @selected_paragraphs = components_params[:paragraphs].presence || []
    flash.now[:danger] = flash_message
    render action, status: :unprocessable_entity
  end

  def build_new_lesson
    lesson = @course.lessons.build(lesson_params.except(
                                     :word_ids, :test_ids, :paragraphs
                                   ))
    lesson.position = @course.lessons.count + 1
    lesson.created_by_id = current_user.id
    lesson
  end

  def lesson_params
    params.require(:lesson).permit(LESSON_PERMITTED)
  end

  def consolidate_components_data form_params
    consolidated = []
    add_paragraphs_to_consolidated(consolidated, form_params[:paragraphs])
    add_words_to_consolidated(consolidated, form_params[:word_ids])
    add_tests_to_consolidated(consolidated, form_params[:test_ids])
    consolidated
  end

  def add_paragraphs_to_consolidated consolidated, paragraphs
    (paragraphs || []).each do |p|
      consolidated << {type: Settings.component_types.paragraph,
                       content: p["content"]}
    end
  end

  def add_words_to_consolidated consolidated, word_ids
    (word_ids || []).compact_blank.each do |id|
      consolidated << {type: Settings.component_types.word, id: id.to_i}
    end
  end

  def add_tests_to_consolidated consolidated, test_ids
    (test_ids || []).compact_blank.each do |id|
      consolidated << {type: Settings.component_types.test, id: id.to_i}
    end
  end

  def build_component_attributes lesson, components_data
    index_in_lesson = 0
    components_data.map do |data|
      index_in_lesson += 1
      attrs = {lesson_id: lesson.id, component_type: data[:type],
               index_in_lesson:, word_id: nil, test_id: nil, content: nil}
      case data[:type]
      when Settings.component_types.word
        attrs[:word_id] = data[:id]
      when Settings.component_types.test
        attrs[:test_id] = data[:id]
      when Settings.component_types.paragraph
        attrs[:content] = data[:content]
      end
      attrs
    end
  end
end
