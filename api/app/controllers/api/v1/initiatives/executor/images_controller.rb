module Api
  module V1
    module Initiatives
      module Executor
        class ImagesController < BaseController
          # Só entrega imagens da tarefa que está rodando agora.
          def show
            image = ::Initiatives::TaskImage.joins(task: :runs)
              .where(initiatives_runs: { status: "running" }).find(params[:id])
            send_data image.data, type: image.content_type, disposition: "attachment"
          end
        end
      end
    end
  end
end
