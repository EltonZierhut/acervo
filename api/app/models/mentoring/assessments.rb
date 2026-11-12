module Mentoring
  # Autoavaliações de uma mentoria: notas por competência e data, e a evolução de cada uma
  # (spec 010, História 4; cálculos em research.md §4).
  class Assessments
    class Invalid < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super(errors.join(", "))
      end
    end

    def initialize(mentorship)
      @mentorship = mentorship
    end

    def dates
      ratings.map(&:rated_on).uniq.sort
    end

    def competencies
      by_competency = ratings.group_by(&:competency_id)
      mentorship.competencies.map do |competency|
        list = by_competency.fetch(competency.id, []).sort_by(&:rated_on)
        first = list.first&.score
        last = list.last&.score
        {
          id: competency.id, mentorship_id: competency.mentorship_id, name: competency.name, position: competency.position,
          ratings: list.map { |r| { rated_on: r.rated_on, score: r.score, comment: r.comment } },
          first:, last:, delta: list.size >= 2 ? last - first : nil
        }
      end
    end

    def to_h
      { dates:, competencies: }
    end

    # Grava a autoavaliação de uma data: substitui as notas existentes nela; nota vazia apaga.
    def save!(rated_on:, entries:)
      date = parse_date(rated_on)
      allowed = mentorship.competencies.index_by(&:id)

      Rating.transaction do
        entries.each do |entry|
          competency = allowed[entry[:competency_id].to_i] or raise Invalid, [ "Competência não pertence a esta mentoria" ]
          rating = competency.ratings.find_or_initialize_by(rated_on: date)
          if entry[:score].blank?
            rating.destroy! if rating.persisted?
            next
          end
          rating.assign_attributes(score: entry[:score], comment: entry[:comment])
          raise Invalid, rating.errors.full_messages.map { |m| "#{competency.name}: #{m}" } unless rating.save
        end
      end
      @ratings = nil
      self
    end

    def destroy_date!(rated_on)
      ratings_scope.where(rated_on: parse_date(rated_on)).delete_all
      @ratings = nil
    end

    private

    attr_reader :mentorship

    def ratings
      @ratings ||= ratings_scope.to_a
    end

    def ratings_scope
      Rating.joins(:competency).where(mentoring_competencies: { mentorship_id: mentorship.id })
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      raise Invalid, [ "Data da autoavaliação inválida" ]
    end
  end
end
