module Mentoring
  # Limites de texto comuns aos models do módulo.
  module TextGuards
    extend ActiveSupport::Concern

    TEXT_MAX_BYTES = 100.kilobytes

    class_methods do
      # Campos Markdown longos: até 100 KB cada.
      def long_text(*fields)
        normalizes(*fields, with: ->(value) { value.presence })
        validate do
          fields.each do |field|
            errors.add(field, "passa do limite de 100 KB") if self[field].to_s.bytesize > TEXT_MAX_BYTES
          end
        end
      end
    end

    included do
      validate :no_null_bytes
    end

    private

    # O PostgreSQL não guarda o caractere nulo em texto.
    def no_null_bytes
      values = attributes.values.flatten.grep(String)
      errors.add(:base, "tem caracteres inválidos") if values.any? { |value| value.include?("\0") }
    end
  end
end
