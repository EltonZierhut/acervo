module Api
  module V1
    module Mentoring
      # JSON do módulo, conforme specs/010-mentoring-module/contracts/mentoring-api.md.
      module Serialization
        private

        def find_mentorship(id = params[:mentorship_id])
          ::Mentoring::Mentorship.find(id)
        end

        def serialize_mentorships(mentorships)
          mentorships = mentorships.to_a
          summaries = ::Mentoring::Overview.summaries(mentorships)
          mentorships.map do |mentorship|
            mentorship.as_json(only: %i[id mentor_name topic description started_on ended_on cadence status created_at updated_at])
              .merge("summary" => summaries.fetch(mentorship.id))
          end
        end

        def serialize_mentorship(mentorship)
          serialize_mentorships([ mentorship ]).first
        end

        def serialize_question(question)
          question.as_json(only: %i[id mentorship_id position prompt answer updated_at])
            .merge("answered" => question.answered?)
        end

        def serialize_goal(goal, progress = nil)
          progress ||= action_progress(:goal_id, [ goal.id ]).fetch(goal.id, { total: 0, done: 0 })
          goal.as_json(only: %i[id mentorship_id title success_criteria description target_on status progress created_at updated_at])
            .merge("overdue" => goal.overdue?, "action_items" => progress)
        end

        def serialize_meeting(meeting, progress = nil)
          progress ||= action_progress(:meeting_id, [ meeting.id ]).fetch(meeting.id, { total: 0, done: 0 })
          meeting.as_json(only: %i[id mentorship_id held_on agenda notes takeaways rating tags created_at updated_at])
            .merge("mentor_name" => meeting.mentorship.mentor_name, "action_items" => progress)
        end

        def serialize_action_item(item)
          item.as_json(only: %i[id mentorship_id meeting_id goal_id title due_on completed_at created_at updated_at])
            .merge("done" => item.done?, "overdue" => item.overdue?,
                   "goal_title" => item.goal&.title, "meeting_held_on" => item.meeting&.held_on)
        end

        def serialize_competency(competency)
          competency.as_json(only: %i[id mentorship_id name position])
        end

        # { id => { total:, done: } } das ações ligadas a objetivos ou encontros.
        def action_progress(column, ids)
          counts = ::Mentoring::ActionItem.where(column => ids)
            .group(column, Arel.sql("completed_at IS NOT NULL")).count
          ids.index_with do |id|
            done = counts.fetch([ id, true ], 0)
            { total: done + counts.fetch([ id, false ], 0), done: }
          end
        end
      end
    end
  end
end
