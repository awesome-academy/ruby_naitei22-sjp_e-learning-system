class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i(google_oauth2)
  has_many :created_courses, class_name: Course.name,
foreign_key: "created_by_id", dependent: :nullify
  has_many :created_lessons, class_name: Lesson.name,
foreign_key: "created_by_id", dependent: :nullify
  has_many :user_courses, dependent: :destroy
  has_many :enrolled_courses, through: :user_courses, source: :course
  has_many :user_lessons, dependent: :destroy
  has_many :lessons, through: :user_lessons
  has_many :admin_course_managers, dependent: :destroy
  has_many :managed_courses, through: :admin_course_managers, source: :course
  has_many :user_words, dependent: :destroy
  has_many :test_results, dependent: :destroy

  has_one_attached :avatar

  attr_accessor :remember_token

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  USER_PERMITTED = %i(
    name email password
    password_confirmation birthday gender
  ).freeze

  enum gender: {male: 0, female: 1, other: 2}
  enum role: {user: 0, admin: 1}

  validates :name,
            presence: true,
            length: {maximum: Settings.user.max_name_length}
  validates :email,
            presence: true,
            length: {maximum: Settings.user.max_email_length},
            format: {with: VALID_EMAIL_REGEX},
            uniqueness: {case_sensitive: false}
  validates :birthday, presence: true, unless: :oauth_user?
  validates :gender, presence: true, unless: :oauth_user?
  validates :uid, uniqueness: {scope: :provider}, allow_nil: true

  validate :birthday_within_100_years
  validate :password_presence_if_confirmation_provided

  class << self
    def new_token
      SecureRandom.urlsafe_base64
    end

    def digest string
      cost = if ActiveModel::SecurePassword.min_cost
               BCrypt::Engine::MIN_COST
             else
               BCrypt::Engine.cost
             end
      BCrypt::Password.create string, cost:
    end
  end

  def remember
    self.remember_token = User.new_token
    update_attribute :remember_digest, User.digest(remember_token)
  end

  def authenticated? remember_token
    return false if remember_digest.nil?

    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  def forget
    update_column :remember_digest, nil
  end

  def self.from_omniauth auth
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
    end
  end

  def oauth_user?
    provider.present? && uid.present?
  end

  private

  def birthday_within_100_years
    return if birthday.blank? || !birthday.is_a?(Date)

    current_date = Time.zone.today
    hundred_years_ago = current_date.prev_year(Settings.user.hundred_years)

    if birthday < hundred_years_ago
      errors.add(:birthday, :too_old)
    elsif birthday > current_date
      errors.add(:birthday, :in_future)
    end
  end

  def password_presence_if_confirmation_provided
    return unless password.blank? && password_confirmation.present?

    errors.add(:password, :password_blank)
  end
end
