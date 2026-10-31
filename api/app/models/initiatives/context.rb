module Initiatives
  # Área da vida que agrupa iniciativas ("Trabalho", "Casa", "Jogo").
  class Context < ApplicationRecord
    DEFAULT_COLOR = "#6b7380".freeze

    has_many :initiatives, class_name: "Initiatives::Initiative", dependent: :nullify

    normalizes :name, with: ->(value) { value.strip }
    normalizes :color, with: ->(value) { value.strip.downcase }

    validates :name, presence: true, length: { maximum: 60 }, uniqueness: { case_sensitive: false }
    validates :color, format: { with: /\A#\h{6}\z/, message: "precisa estar no formato #rrggbb" }

    scope :ordered, -> { order(Arel.sql("lower(name)")) }
  end
end
