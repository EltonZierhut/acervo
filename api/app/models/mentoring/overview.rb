module Mentoring
  # Indicadores do painel de uma mentoria (spec 010, História 5), em poucas consultas agregadas.
  class Overview
    NEXT_ACTIONS = 5

    def initialize(mentorship, today: Date.current)
      @mentorship = mentorship
      @today = today
    end

    def to_h
      { questions:, goals:, action_items:, meetings:, competencies: }
    end

    # Resumo curto de várias mentorias para a lista, sem uma consulta por mentoria.
    def self.summaries(mentorships, today: Date.current)
      ids = mentorships.map(&:id)
      goals = Goal.where(mentorship_id: ids).group(:mentorship_id, :status).count
      open_actions = ActionItem.where(mentorship_id: ids).pending.group(:mentorship_id).count
      last_meetings = Meeting.where(mentorship_id: ids, held_on: ..today).group(:mentorship_id).maximum(:held_on)

      ids.index_with do |id|
        {
          goals_open: goals.fetch([ id, "not_started" ], 0) + goals.fetch([ id, "in_progress" ], 0),
          goals_achieved: goals.fetch([ id, "achieved" ], 0),
          action_items_open: open_actions.fetch(id, 0),
          last_meeting_on: last_meetings[id]
        }
      end
    end

    private

    attr_reader :mentorship, :today

    def questions
      scope = mentorship.questions.unscope(:order)
      { total: scope.count, answered: scope.answered.count }
    end

    def goals
      scope = mentorship.goals.counted
      average = scope.average(:progress)
      { total: scope.count, achieved: scope.where(status: "achieved").count,
        average_progress: average&.round }
    end

    def action_items
      scope = mentorship.action_items
      counts = scope.group(Arel.sql("completed_at IS NOT NULL")).count
      {
        total: counts.values.sum,
        done: counts.fetch(true, 0),
        overdue: scope.pending.where(due_on: ...today).count,
        next: scope.pending.includes(:goal, :meeting).ordered.limit(NEXT_ACTIONS).to_a
      }
    end

    def meetings
      held = mentorship.meetings.where(held_on: ..today)
      last = held.maximum(:held_on)
      average = held.average(:rating)
      {
        held: held.count,
        last_held_on: last,
        days_since_last: last && (today - last).to_i,
        next_on: mentorship.meetings.where("held_on > ?", today).minimum(:held_on),
        average_rating: average&.to_f&.round(1)
      }
    end

    def competencies
      deltas = Assessments.new(mentorship).competencies.filter_map { |competency| competency[:delta] }
      {
        total: mentorship.competencies.unscope(:order).count,
        assessments: Rating.joins(:competency).where(mentoring_competencies: { mentorship_id: mentorship.id })
          .distinct.count(:rated_on),
        average_delta: deltas.empty? ? nil : (deltas.sum.to_f / deltas.size).round(1)
      }
    end
  end
end
