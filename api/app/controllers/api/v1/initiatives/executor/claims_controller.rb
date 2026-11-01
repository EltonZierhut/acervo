module Api
  module V1
    module Initiatives
      module Executor
        class ClaimsController < BaseController
          def create
            run = ::Initiatives::Run.claim
            return head(:no_content) unless run

            task = run.task
            render json: { run: {
              id: run.id,
              repository: run.repository,
              task: task.as_json(only: %i[id initiative_id title description]),
              images: task.images.without_data.ordered.as_json(only: %i[id filename content_type]),
              links: task.links.ordered.as_json(only: %i[url title]),
              questions: run.questions.ordered.as_json(only: %i[body answer])
            } }
          end
        end
      end
    end
  end
end
