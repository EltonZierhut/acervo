module Flashcards
  # Fila de estudo de um baralho no dia (spec 009, FR-007): primeiro os cartões em aprendizado já vencidos,
  # depois as revisões que vencem até o fim do dia, depois os novos, respeitando os limites diários.
  class StudyQueue
    attr_reader :deck, :now

    # Contagens do dia de vários baralhos com poucas consultas agregadas (lista de baralhos).
    # Devolve { deck_id => { new:, learning:, review: } }.
    def self.counts_for(decks, now: Time.current)
      decks = decks.to_a
      return {} if decks.empty?

      day_start = StudyDay.start(now)
      day_end = StudyDay.finish(now)
      ids = decks.map(&:id)

      pending = Card.joins(:note).where(flashcards_notes: { deck_id: ids, suspended: false })
        .group("flashcards_notes.deck_id")
        .pluck(Arel.sql("flashcards_notes.deck_id"),
               Arel.sql("COUNT(*) FILTER (WHERE flashcards_cards.state = 'new')"),
               Arel.sql(Card.sanitize_sql_array([ "COUNT(*) FILTER (WHERE flashcards_cards.state IN ('learning', 'relearning') AND flashcards_cards.due_at < ?)", day_end ])),
               Arel.sql(Card.sanitize_sql_array([ "COUNT(*) FILTER (WHERE flashcards_cards.state = 'review' AND flashcards_cards.due_at < ?)", day_end ])))
        .to_h { |deck_id, *counts| [ deck_id, counts ] }

      done = Review.joins(card: :note).where(flashcards_notes: { deck_id: ids }, reviewed_at: day_start..)
        .group("flashcards_notes.deck_id", "flashcards_reviews.state_before").count

      decks.to_h do |deck|
        new_count, learning_count, review_count = pending.fetch(deck.id, [ 0, 0, 0 ])
        new_left = [ deck.new_per_day - done.fetch([ deck.id, "new" ], 0), 0 ].max
        reviews_left = [ deck.reviews_per_day - done.fetch([ deck.id, "review" ], 0), 0 ].max
        [ deck.id, { new: [ new_count, new_left ].min, learning: learning_count, review: [ review_count, reviews_left ].min } ]
      end
    end

    def initialize(deck, now: Time.current)
      @deck = deck
      @now = now
    end

    def counts
      @counts ||= self.class.counts_for([ deck ], now:).fetch(deck.id)
    end

    def next_card
      card = cards.includes(:note).in_steps.where(due_at: ..now).order(:due_at, :id).first
      card ||= cards.includes(:note).where(state: "review", due_at: ...day_end).order(:due_at, :id).first if counts[:review].positive?
      # Todos os "frente → verso" antes dos invertidos, para não mostrar os dois lados da mesma nota seguidos.
      card ||= cards.includes(:note).where(state: "new").order(:ordinal, "flashcards_notes.created_at", :id).first if counts[:new].positive?
      card
    end

    # Próximo cartão em aprendizado que vence ainda hoje (quando não há nada para agora).
    def next_due_at
      cards.in_steps.where(due_at: now...day_end).minimum(:due_at)
    end

    # Cartões que vencem no próximo dia de estudo.
    def due_tomorrow
      cards.where.not(state: "new").where(due_at: day_end...day_end.advance(days: 1)).count
    end

    private

    def cards
      Card.studyable_in(deck.id)
    end

    def day_end
      @day_end ||= StudyDay.finish(now)
    end
  end
end
