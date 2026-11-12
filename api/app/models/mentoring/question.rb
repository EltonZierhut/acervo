module Mentoring
  # Pergunta do questionário inicial, com a resposta.
  class Question < ApplicationRecord
    include TextGuards

    belongs_to :mentorship

    normalizes :prompt, with: ->(value) { value.to_s.strip }
    long_text :answer

    validates :prompt, presence: true, length: { maximum: 500 }
    validates :position, numericality: { only_integer: true, greater_than: 0 }

    before_validation :append_to_end, on: :create

    scope :answered, -> { where("btrim(coalesce(answer, '')) <> ''") }

    def answered?
      answer.to_s.strip.present?
    end

    # Troca de lugar com a pergunta vizinha. Devolve false se já estiver na ponta.
    def move!(direction)
      siblings = mentorship.questions.to_a
      index = siblings.index(self)
      target = direction.to_s == "up" ? index - 1 : index + 1
      return false if target.negative? || target >= siblings.size

      siblings[index], siblings[target] = siblings[target], siblings[index]
      transaction do
        siblings.each_with_index do |question, i|
          question.update_columns(position: i + 1, updated_at: Time.current) if question.position != i + 1
        end
      end
      true
    end

    private

    def append_to_end
      return if position.present? || mentorship.nil?

      self.position = (mentorship.questions.maximum(:position) || 0) + 1
    end
  end
end
