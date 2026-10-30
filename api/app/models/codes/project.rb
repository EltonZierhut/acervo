module Codes
  class Project < ApplicationRecord
    include Searchable
    include NormalizesTags

    searchable_partial_columns :name, :description

    has_many :snippets, class_name: "Codes::Snippet", dependent: :nullify

    validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 120 }
    validates :repository_url, format: { with: %r{\Ahttps?://}i }, allow_blank: true
  end
end
