class User < ApplicationRecord
  attr_accessor :remember_token

  has_secure_password

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  USER_PERMITTED = %i(
    name email password
    password_confirmation birthday gender
  ).freeze

  enum gender: {female: 0, male: 1, other: 2}

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

  def self.find_or_create_from_auth_hash auth
    user = find_by(email: auth.info.email)

    if user
      user.update(provider: auth.provider, uid: auth.uid) unless user.provider
      user
    else
      create!(
        name: auth.info.name,
        email: auth.info.email,
        provider: auth.provider,
        uid: auth.uid,
        password: SecureRandom.hex(10)
      )
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
end
