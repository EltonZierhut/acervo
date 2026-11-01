module Api
  module V1
    module Initiatives
      class TaskImagesController < ApplicationController
        before_action :set_task, only: %i[index create]

        def index
          render json: @task.images.without_data.ordered.map { |image| serialize(image) }
        end

        # POST .../tasks/:task_id/task_images?filename=tela.png, com os bytes no corpo.
        def create
          return head(:unsupported_media_type) unless accepted_write_media_type?

          max = ::Initiatives::TaskImage::MAX_BYTES
          data = request.body.read(max + 1).to_s
          image = ::Initiatives::TaskImage.attach(@task, filename: params[:filename], data:)
          image.persisted? ? render(json: serialize(image), status: :created) : render_errors(image)
        end

        def show
          image = ::Initiatives::TaskImage.find(params[:id])
          response.headers["X-Content-Type-Options"] = "nosniff"
          response.headers["Content-Security-Policy"] = "default-src 'none'; sandbox"
          response.headers["Cache-Control"] = "private, max-age=3600"
          send_data image.data, type: image.content_type, disposition: "inline", filename: image.filename
        end

        def destroy
          ::Initiatives::TaskImage.without_data.find(params[:id]).destroy
          head :no_content
        end

        private

        # Um formulário de outro site não consegue enviar image/*, então a proteção contra CSRF continua.
        def accepted_write_media_type?
          action_name == "create" && request.media_type.to_s.start_with?("image/")
        end

        def set_task
          @task = ::Initiatives::Task.find(params[:task_id])
        end

        def serialize(image)
          image.as_json(only: %i[id filename content_type byte_size]).merge(
            url: "/api/v1/initiatives/task_images/#{image.id}"
          )
        end
      end
    end
  end
end
