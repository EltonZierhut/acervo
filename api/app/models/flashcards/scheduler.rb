module Flashcards
  # Agendamento SM-2 no padrão do Anki (spec 009, research.md). Não acessa o banco: recebe o cartão e a
  # resposta e devolve o novo agendamento, para ser testado regra por regra.
  #
  # Respostas: 1 Errei, 2 Difícil, 3 Bom, 4 Fácil.
  class Scheduler
    LEARNING_STEPS = [ 1, 10 ].freeze # minutos
    RELEARNING_STEPS = [ 10 ].freeze # minutos
    GRADUATING_INTERVAL = 1 # dias
    EASY_INTERVAL = 4 # dias
    STARTING_EASE = 2500 # milésimos (2,5)
    MINIMUM_EASE = 1300
    EASY_BONUS = 1.3
    HARD_MULTIPLIER = 1.2
    MAXIMUM_INTERVAL = 36_500
    RATINGS = (1..4)

    # `interval_days` guarda o intervalo de revisão (no reaprendizado, o que valerá ao voltar à revisão).
    Result = Data.define(:state, :step_index, :interval_days, :ease, :lapses, :due_at) do
      def in_steps?
        %w[learning relearning].include?(state)
      end
    end

    def initialize(now: Time.current, fuzz: true, random: Random.new)
      @now = now
      @fuzz = fuzz
      @random = random
    end

    def answer(card, rating)
      rating = Integer(rating)
      raise ArgumentError, "resposta precisa ser de 1 a 4" unless RATINGS.cover?(rating)

      case card.state
      when "new", "learning" then learning(card, rating)
      when "review" then review(card, rating)
      when "relearning" then relearning(card, rating)
      else raise ArgumentError, "estado desconhecido: #{card.state}"
      end
    end

    # O que cada resposta daria, sem variação (para mostrar nos botões).
    def preview(card)
      RATINGS.to_h { |rating| [ rating, answer(card, rating) ] }
    end

    # Texto curto do intervalo: "1 min", "2 h", "1 dia", "3 meses", "1,2 ano".
    def self.label(result, now = Time.current)
      return minutes_label(((result.due_at - now) / 60.0).round) if result.in_steps?

      days = result.interval_days
      return "#{days} #{days == 1 ? 'dia' : 'dias'}" if days < 30

      months = (days / 30.0).round(1)
      return "#{number(months)} #{months < 2 ? 'mês' : 'meses'}" if days < 365

      years = (days / 365.0).round(1)
      "#{number(years)} #{years < 2 ? 'ano' : 'anos'}"
    end

    def self.minutes_label(minutes)
      minutes = [ minutes, 1 ].max
      return "#{minutes} min" if minutes < 60

      "#{number((minutes / 60.0).round(1))} h"
    end

    def self.number(value)
      value.to_s.delete_suffix(".0").tr(".", ",")
    end

    private

    def learning(card, rating)
      step = card.state == "new" ? 0 : card.step_index.clamp(0, LEARNING_STEPS.size - 1)
      ease = card.state == "new" ? STARTING_EASE : card.ease

      case rating
      when 1 then in_steps("learning", 0, LEARNING_STEPS.first, card, ease:)
      when 2 then in_steps("learning", step, hard_delay(LEARNING_STEPS, step), card, ease:)
      when 3
        next_step = step + 1
        if next_step < LEARNING_STEPS.size
          in_steps("learning", next_step, LEARNING_STEPS[next_step], card, ease:)
        else
          to_review(GRADUATING_INTERVAL, ease:, lapses: card.lapses)
        end
      when 4 then to_review(EASY_INTERVAL, ease:, lapses: card.lapses)
      end
    end

    def review(card, rating)
      interval = [ card.interval_days, 1 ].max
      hard = [ interval + 1, (interval * HARD_MULTIPLIER).round ].max
      good = [ hard + 1, (interval * card.ease / 1000.0).round ].max
      easy = [ good + 1, (interval * card.ease / 1000.0 * EASY_BONUS).round ].max

      case rating
      when 1
        Result.new(state: "relearning", step_index: 0, interval_days: GRADUATING_INTERVAL,
                   ease: [ card.ease - 200, MINIMUM_EASE ].max, lapses: card.lapses + 1,
                   due_at: @now + RELEARNING_STEPS.first.minutes)
      when 2 then to_review(hard, ease: [ card.ease - 150, MINIMUM_EASE ].max, lapses: card.lapses)
      when 3 then to_review(good, ease: card.ease, lapses: card.lapses)
      when 4 then to_review(easy, ease: card.ease + 150, lapses: card.lapses)
      end
    end

    def relearning(card, rating)
      step = card.step_index.clamp(0, RELEARNING_STEPS.size - 1)
      interval = [ card.interval_days, 1 ].max

      case rating
      when 1 then in_steps("relearning", 0, RELEARNING_STEPS.first, card)
      when 2 then in_steps("relearning", step, hard_delay(RELEARNING_STEPS, step), card)
      when 3
        next_step = step + 1
        if next_step < RELEARNING_STEPS.size
          in_steps("relearning", next_step, RELEARNING_STEPS[next_step], card)
        else
          to_review(interval, ease: card.ease, lapses: card.lapses)
        end
      when 4 then to_review(interval + 1, ease: card.ease, lapses: card.lapses)
      end
    end

    # "Difícil" repete o passo; no primeiro de dois ou mais passos, usa a média dos dois primeiros.
    def hard_delay(steps, step)
      step.zero? && steps.size > 1 ? (steps[0] + steps[1]) / 2.0 : steps[step]
    end

    def in_steps(state, step, minutes, card, ease: card.ease)
      Result.new(state:, step_index: step, interval_days: card.interval_days, ease:, lapses: card.lapses,
                 due_at: @now + (minutes * 60).round.seconds)
    end

    def to_review(days, ease:, lapses:)
      days = fuzz(days.clamp(1, MAXIMUM_INTERVAL))
      Result.new(state: "review", step_index: 0, interval_days: days, ease:, lapses:,
                 due_at: StudyDay.after(days, @now))
    end

    # Variação de ±5% (pelo menos 1 dia) acima de 2 dias, para os cartões não vencerem todos juntos.
    def fuzz(days)
      return days if !@fuzz || days <= 2

      delta = [ (days * 0.05).round, 1 ].max
      (days + @random.rand(-delta..delta)).clamp(1, MAXIMUM_INTERVAL)
    end
  end
end
