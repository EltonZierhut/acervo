module Api
  module V1
    module Initiatives
      module RunSerialization
        private

        def serialize_run(run)
          task = run.task
          run.as_json(only: %i[id task_id repository status enqueued_at started_at finished_at failure_kind
                               failure_reason summary pull_request_url]).merge(
            task_title: task.title,
            initiative_id: task.initiative_id,
            initiative_name: task.initiative.name,
            questions: run.questions.sort_by(&:id).map { |q| q.as_json(only: %i[id body answer answered_at]) }
          )
        end
      end
    end
  end
end
