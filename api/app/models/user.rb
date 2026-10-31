# Conta de acesso ao Acervo. Nesta versão existe um único usuário (regra aplicada
# no comando de criação, não aqui), mas o model já suporta vários.
class User < ApplicationRecord
  PASSWORD_MIN_LENGTH = 12

  has_secure_password # inclui o limite de 72 bytes do bcrypt
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: PASSWORD_MIN_LENGTH }, allow_nil: true

  # Troca a senha e encerra todas as sessões abertas. Retorna quantas foram encerradas.
  def reset_password!(password, password_confirmation)
    transaction do
      update!(password:, password_confirmation:)
      Session.where(user_id: id).delete_all
    end
  end
end
