class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :held_slots, class_name: "Slot", foreign_key: :held_by_user_id, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_digest.last(10)
  end

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 12 }, if: -> { new_record? || password.present? }
end
