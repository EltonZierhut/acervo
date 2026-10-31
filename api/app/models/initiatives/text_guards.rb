module Initiatives
  # Regras de texto comuns aos models do módulo.
  module TextGuards
    extend ActiveSupport::Concern

    # Descrições longas o bastante para anotações, e curtas o bastante para o índice de busca.
    DESCRIPTION_MAX_LENGTH = 50_000

    included do
      validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }
      validate :no_null_bytes
    end

    private

    # O PostgreSQL não guarda o caractere nulo em texto.
    def no_null_bytes
      values = attributes.values.flat_map { |value| Array(value) }.grep(String)
      errors.add(:base, "O texto tem caracteres inválidos") if values.any? { |value| value.include?("\0") }
    end
  end
end
