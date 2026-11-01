module Initiatives
  class TaskLink < ApplicationRecord
    belongs_to :task, class_name: "Initiatives::Task"

    scope :ordered, -> { order(:position, :id) }

    normalizes :url, with: ->(value) { value.strip }
    normalizes :title, with: ->(value) { value.strip.presence }

    validates :url, presence: true, length: { maximum: 2_048 }
    validates :title, length: { maximum: 200 }
    validate :url_is_http

    before_create { self.position = self.class.where(task_id:).maximum(:position).to_i + 1 }

    private

    def url_is_http
      return if url.blank?

      uri = URI.parse(url)
      return if uri.is_a?(URI::HTTP) && uri.host.present?

      errors.add(:url, "precisa ser um endereço http ou https")
    rescue URI::InvalidURIError
      errors.add(:url, "precisa ser um endereço http ou https")
    end
  end
end
