module Initiatives
  # Dúvida da IA durante uma execução, com a resposta do usuário.
  class RunQuestion < ApplicationRecord
    MAX_ANSWER_LENGTH = 10_000

    belongs_to :run, class_name: "Initiatives::Run"

    scope :ordered, -> { order(:id) }
    scope :pending, -> { where(answered_at: nil) }

    validates :body, presence: true
    validates :answer, length: { maximum: MAX_ANSWER_LENGTH }
  end
end
