# Aceita tags como array ou como texto "a, b, c" e guarda em minúsculas, sem repetição.
module NormalizesTags
  extend ActiveSupport::Concern

  included do
    normalizes :tags, with: lambda { |value|
      Array(value).map { |tag| tag.to_s.strip.downcase }.reject(&:blank?).uniq
    }
  end

  # O texto precisa ser separado antes da conversão do tipo array, que o leria como literal do Postgres.
  def tags=(value)
    super(value.is_a?(String) ? value.split(",") : Array(value))
  end
end
