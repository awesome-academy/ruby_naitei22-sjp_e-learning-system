class Word < ApplicationRecord
  has_many :components, dependent: :destroy

  enum word_type: {
    noun: 0,
    pronoun: 1,
    verb: 2,
    adjective: 3,
    adverb: 4,
    preposition: 5,
    conjunction: 6,
    interjection: 7
  }

  # Validations
  validates :content, presence: true
  validates :meaning, presence: true
  validates :word_type, presence: true, inclusion: {in: word_types.keys}

  # Scopes
  scope :by_type, ->(word_type){where(word_type:)}
  scope :recent, ->{order(created_at: :desc)}

  scope :by_content, (lambda do |query|
    return all if query.blank?

    where("content LIKE ?", "%#{query}%")
  end)

  scope :by_time, lambda {|filter_time|
    case filter_time
    when "today"
      where("created_at >= ?", Time.zone.now.beginning_of_day)
    when "last_7_days", "last_30_days"
      days = Settings.word.filter_days[filter_time].to_i
      where("created_at >= ?", days.days.ago.beginning_of_day)
    else
      all
    end
  }

  scope :search, lambda {|q, field = nil|
    if q.present?
      case field
      when "content"
        where("content LIKE ?", "#{q}%")
      when "meaning"
        where("meaning LIKE ?", "#{q}%")
      else
        where("content LIKE ? OR meaning LIKE ?", "#{q}%", "#{q}%")
      end
    end
  }

  scope :filter_by_type, ->(type){where(word_type: type) if type.present?}

  scope :sorted, lambda {|sort|
    case sort
    when "alphabetical_desc"
      order(content: :desc)
    when "newest"
      order(created_at: :desc)
    when "oldest"
      order(created_at: :asc)
    when "word_type"
      order(:word_type, :content)
    else
      order(content: :asc)
    end
  }

  def self.learned_word_ids_for user
    UserWord.joins(:component)
            .where(user_id: user.id)
            .pluck("components.word_id")
            .uniq
  end

  scope :filter_by_status, lambda {|status, user|
    return all if status.blank?

    learned_ids = learned_word_ids_for(user)

    case status
    when "learned"
      where(id: learned_ids)
    when "not_learned"
      where.not(id: learned_ids)
    else
      all
    end
  }

  def learned_by? user
    UserWord.joins(:component)
            .exists?(user_id: user.id, components: {word_id: id})
  end
end
