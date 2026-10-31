module Codes
  class Snippet < ApplicationRecord
    include Searchable
    include NormalizesTags

    CONTENT_MAX_BYTES = 1.megabyte
    DISPLAY_TITLE_LENGTH = 200

    searchable_partial_columns :title, :content, :description, :tags_text

    validates :title, length: { maximum: 200 }
    validates :content, presence: true
    validate :content_within_limit
    validate :no_null_bytes

    normalizes :title, with: ->(value) { value.strip.presence }
    normalizes :description, with: ->(value) { value.presence }
    normalizes :language, with: ->(value) { value.to_s.strip.downcase.presence }

    scope :with_tag, ->(tag) { where("? = ANY(tags)", tag.to_s.downcase) }
    scope :in_language, ->(language) { where(language: language.to_s.downcase) }

    # Nome mostrado na lista: o título ou, sem ele, a primeira linha com texto.
    def display_title
      title || content.to_s.each_line.find(&:present?).to_s.strip.truncate(DISPLAY_TITLE_LENGTH)
    end

    private

    def content_within_limit
      errors.add(:content, "passa do limite de 1 MB") if content.to_s.bytesize > CONTENT_MAX_BYTES
    end

    # O PostgreSQL não guarda o caractere nulo em texto.
    def no_null_bytes
      values = [ title, content, description, language, *tags ]
      errors.add(:content, "tem caracteres inválidos") if values.any? { |value| value.to_s.include?("\0") }
    end
  end
end
