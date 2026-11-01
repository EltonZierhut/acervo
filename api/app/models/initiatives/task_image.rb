module Initiatives
  # Imagem anexada a uma tarefa. Os bytes ficam na coluna "data"; use "without_data" em listagens.
  class TaskImage < ApplicationRecord
    MAX_BYTES = 10.megabytes
    MAX_PER_TASK = 10
    METADATA_COLUMNS = %i[id task_id filename content_type byte_size position created_at updated_at].freeze

    belongs_to :task, class_name: "Initiatives::Task"

    scope :without_data, -> { select(*METADATA_COLUMNS) }
    scope :ordered, -> { order(:position, :id) }

    normalizes :filename, with: lambda { |value|
      value.to_s.tr("\\", "/").split("/").last.to_s.gsub(/[[:cntrl:]]/, "").strip.first(255).presence || "imagem"
    }, apply_to_nil: true

    validates :filename, presence: true
    validate :data_is_acceptable, on: :create
    validate :task_has_room, on: :create

    before_validation :fill_from_data, on: :create

    # O tipo vem dos primeiros bytes, nunca do que o navegador informou. SVG fica de fora por poder ter script.
    def self.detect_content_type(bytes)
      head = bytes.to_s.byteslice(0, 12).to_s.b
      return "image/png" if head.start_with?("\x89PNG\r\n\x1A\n".b)
      return "image/jpeg" if head.start_with?("\xFF\xD8\xFF".b)
      return "image/gif" if head.start_with?("GIF87a".b, "GIF89a".b)
      return "image/webp" if head.start_with?("RIFF".b) && head.byteslice(8, 4) == "WEBP".b

      nil
    end

    # A trava na tarefa impede que envios simultâneos passem do limite.
    def self.attach(task, filename:, data:)
      task.with_lock do
        position = where(task_id: task.id).maximum(:position).to_i + 1
        create(task:, filename:, data:, position:)
      end
    end

    private

    def fill_from_data
      self.content_type = self.class.detect_content_type(data)
      self.byte_size = data.to_s.bytesize
    end

    def data_is_acceptable
      errors.add(:base, "Envie uma imagem PNG, JPEG, WEBP ou GIF") if content_type.nil?
      errors.add(:base, "A imagem passa do limite de 10 MB") if byte_size.to_i > MAX_BYTES
    end

    def task_has_room
      return unless task_id
      return if self.class.where(task_id:).count < MAX_PER_TASK

      errors.add(:base, "A tarefa já tem o limite de #{MAX_PER_TASK} imagens")
    end
  end
end
