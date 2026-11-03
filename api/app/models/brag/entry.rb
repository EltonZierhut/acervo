module Brag
  class Entry < ApplicationRecord
    include Searchable
    include NormalizesTags

    TEXT_MAX_BYTES = 100.kilobytes
    LINKS_MAX = 20

    searchable_partial_columns :title, :description, :category, :project, :impact, :metrics, :tags_text

    validates :title, presence: true, length: { maximum: 200 }
    validates :achieved_on, presence: true
    validates :category, :project, length: { maximum: 100 }
    validate :texts_within_limit
    validate :links_are_http_urls
    validate :no_null_bytes

    normalizes :title, with: ->(value) { value.to_s.strip }
    normalizes :category, :project, with: ->(value) { value.to_s.strip.presence }
    normalizes :description, :impact, :metrics, with: ->(value) { value.presence }
    normalizes :evidence_links, with: lambda { |value|
      Array(value).map { |link| link.to_s.strip }.reject(&:blank?).uniq
    }

    scope :with_tag, ->(tag) { where("? = ANY(tags)", tag.to_s.downcase) }
    scope :in_category, ->(category) { where(category: category.to_s.strip) }
    scope :in_year, ->(year) { where(achieved_on: Date.new(year.to_i, 1, 1)..Date.new(year.to_i, 12, 31)) }

    # Links como texto aceitam um por linha.
    def evidence_links=(value)
      super(value.is_a?(String) ? value.split(/\r?\n/) : Array(value))
    end

    private

    def texts_within_limit
      %i[description impact metrics].each do |field|
        errors.add(field, "passa do limite de 100 KB") if self[field].to_s.bytesize > TEXT_MAX_BYTES
      end
    end

    def links_are_http_urls
      errors.add(:evidence_links, "aceita no máximo #{LINKS_MAX} links") if evidence_links.size > LINKS_MAX
      invalid = evidence_links.reject { |link| link.length <= 2000 && link.match?(%r{\Ahttps?://[^\s]+\z}i) }
      errors.add(:evidence_links, "precisa ter só endereços http(s) válidos") if invalid.any?
    end

    # O PostgreSQL não guarda o caractere nulo em texto.
    def no_null_bytes
      values = [ title, description, category, impact, metrics, project, *tags, *evidence_links ]
      errors.add(:base, "tem caracteres inválidos") if values.any? { |value| value.to_s.include?("\0") }
    end
  end
end
