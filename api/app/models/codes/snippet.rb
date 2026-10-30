module Codes
  class Snippet < ApplicationRecord
    include Searchable
    include NormalizesTags

    searchable_partial_columns :title, :content

    belongs_to :project, class_name: "Codes::Project", optional: true

    validates :title, presence: true, length: { maximum: 200 }
    validates :content, presence: true

    normalizes :language, with: ->(value) { value.to_s.strip.downcase.presence }

    scope :with_tag, ->(tag) { where("? = ANY(tags)", tag.to_s.downcase) }
    scope :in_language, ->(language) { where(language: language.to_s.downcase) }
  end
end
