module Initiatives
  # O programa que processa a fila no computador do usuário. Há no máximo um.
  class Executor < ApplicationRecord
    AVAILABLE_WITHIN = 2.minutes
    SEEN_PRECISION = 15.seconds

    # Cria o token e invalida o anterior. O valor só existe neste retorno; o banco guarda o SHA-256.
    def self.rotate_token!
      token = SecureRandom.hex(32)
      transaction do
        delete_all
        create!(token_digest: digest(token))
      end
      token
    end

    def self.authenticate(token)
      return if token.blank?

      find_by(token_digest: digest(token))
    end

    def self.digest(token) = Digest::SHA256.hexdigest(token)

    def available? = last_seen_at.present? && last_seen_at > AVAILABLE_WITHIN.ago

    def seen!(version: nil)
      attributes = {}
      attributes[:last_seen_at] = Time.current if last_seen_at.nil? || last_seen_at < SEEN_PRECISION.ago
      attributes[:version] = version if version.present? && version != self.version
      update!(attributes) if attributes.any?
    end
  end
end
