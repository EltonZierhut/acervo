module Api
  module V1
    module Flashcards
      # JSON do módulo, conforme specs/009-flashcards-module/contracts/flashcards-api.md.
      module Serialization
        private

        def serialize_deck(deck, counts:, card_count:)
          deck.as_json(only: %i[id name description new_per_day reviews_per_day created_at updated_at])
            .merge("card_count" => card_count, "due" => counts)
        end

        def serialize_decks(decks, now: Time.current)
          decks = decks.to_a
          counts = ::Flashcards::StudyQueue.counts_for(decks, now:)
          totals = ::Flashcards::Card.joins(:note).where(flashcards_notes: { deck_id: decks.map(&:id) })
            .group("flashcards_notes.deck_id").count
          decks.map do |deck|
            serialize_deck(deck, counts: counts.fetch(deck.id), card_count: totals.fetch(deck.id, 0))
          end
        end

        def serialize_note(note)
          note.as_json(only: %i[id deck_id note_type front back tags suspended created_at updated_at])
            .merge("cards" => note.cards.map { |card| serialize_card(card) })
        end

        def serialize_card(card)
          card.as_json(only: %i[id ordinal state due_at interval_days ease reps lapses])
        end

        def study_payload(deck, now: Time.current)
          queue = ::Flashcards::StudyQueue.new(deck, now:)
          card = queue.next_card
          {
            deck: { id: deck.id, name: deck.name },
            counts: queue.counts,
            card: card && serialize_study_card(card, now:),
            next_due_at: card ? nil : queue.next_due_at,
            due_tomorrow: queue.due_tomorrow
          }
        end

        def serialize_study_card(card, now:)
          preview = ::Flashcards::Scheduler.new(now:, fuzz: false).preview(card)
          {
            id: card.id, note_id: card.note_id, ordinal: card.ordinal, state: card.state,
            question: card.question, answer: card.answer, tags: card.note.tags,
            intervals: preview.to_h { |rating, result| [ rating.to_s, ::Flashcards::Scheduler.label(result, now) ] }
          }
        end
      end
    end
  end
end
