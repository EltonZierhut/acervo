# Aceita tags como array ou como texto "a, b, c" e guarda em minúsculas, sem repetição.
module NormalizesTags
  extend ActiveSupport::Concern

  included do
    normalizes :tags, with: lambda { |value|
      list = value.is_a?(String) ? value.split(",") : Array(value)
      list.map { |tag| tag.to_s.strip.downcase }.reject(&:blank?).uniq
    }
  end
end
