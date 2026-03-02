class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :held_slots, class_name: "Slot", foreign_key: :held_by_user_id, dependent: :nullify
  has_one_attached :avatar

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_digest.last(10)
  end

  generates_token_for :email_verification, expires_in: 24.hours do
    email_verified_at
  end

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 12 }, if: -> { new_record? || password.present? }
  validate :acceptable_avatar, if: -> { avatar.attached? }

  def email_verified?
    email_verified_at.present?
  end

  def verify!
    update!(email_verified_at: Time.current)
  end

  private

    def acceptable_avatar
      unless avatar.content_type.in?(%w[image/jpeg image/png image/webp])
        errors.add(:avatar, "must be a JPEG, PNG, or WebP image")
      end
      if avatar.byte_size > 5.megabytes
        errors.add(:avatar, "must be less than 5MB")
      end
    end
end
