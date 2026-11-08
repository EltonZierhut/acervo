require "test_helper"

module Flashcards
  class StudyQueueTest < ActiveSupport::TestCase
    setup do
      @now = Time.zone.local(2026, 11, 7, 10, 0)
      @deck = Deck.create!(name: "Inglês", new_per_day: 2)
    end

    def queue(at = @now)
      StudyQueue.new(@deck.reload, now: at)
    end

    def note(front)
      @deck.notes.create!(front:, back: "#{front} (verso)")
    end

    test "baralho novo tem limites padrão" do
      deck = Deck.create!(name: "Outro")
      assert_equal [ 20, 200 ], [ deck.new_per_day, deck.reviews_per_day ]
    end

    test "nome do baralho é único sem diferenciar maiúsculas" do
      assert_not Deck.new(name: " inglês ").valid?
    end

    test "novos respeitam o limite diário, contando os já estudados hoje" do
      3.times { |i| note("palavra #{i}") }
      assert_equal({ new: 2, learning: 0, review: 0 }, queue.counts)

      queue.next_card.answer!(3, now: @now)
      counts = queue(@now + 1.minute).counts
      assert_equal [ 1, 1 ], [ counts[:new], counts[:learning] ]
    end

    test "ordem: aprendizado vencido, depois revisões, depois novos" do
      fresh = note("nova").cards.first
      learning = note("aprendendo").cards.first
      review = note("revisando").cards.first
      learning.update!(state: "learning", step_index: 1, due_at: @now - 1.minute)
      review.update!(state: "review", interval_days: 3, due_at: StudyDay.start(@now))

      assert_equal learning, queue.next_card
      learning.update!(due_at: @now + 5.minutes)
      assert_equal review, queue.next_card
      review.update!(due_at: StudyDay.after(2, @now))
      assert_equal fresh, queue.next_card
    end

    test "sem nada para agora informa o próximo vencimento e os de amanhã" do
      card = note("x").cards.first
      card.update!(state: "learning", step_index: 1, due_at: @now + 8.minutes)
      other = note("y").cards.first
      other.update!(state: "review", interval_days: 1, due_at: StudyDay.after(1, @now))
      @deck.update!(new_per_day: 0)

      assert_nil queue.next_card
      assert_equal @now + 8.minutes, queue.next_due_at
      assert_equal 1, queue.due_tomorrow
    end

    test "notas suspensas ficam fora da fila" do
      note("x").update!(suspended: true)
      assert_nil queue.next_card
      assert_equal({ new: 0, learning: 0, review: 0 }, queue.counts)
    end

    test "o dia de estudo só vira às 4h" do
      note("x").cards.first.answer!(3, now: @now)
      note("y").cards.first.answer!(3, now: @now)
      note("z")

      assert_equal 0, queue(Time.zone.local(2026, 11, 8, 3, 0)).counts[:new]
      assert_equal 1, queue(Time.zone.local(2026, 11, 8, 4, 0)).counts[:new]
    end
  end
end
