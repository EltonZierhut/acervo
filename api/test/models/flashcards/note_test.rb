require "test_helper"

module Flashcards
  class NoteTest < ActiveSupport::TestCase
    setup { @deck = Deck.create!(name: "Inglês") }

    test "frente e verso são obrigatórios e o tipo precisa ser válido" do
      assert_not @deck.notes.new(front: "a", back: " ").valid?
      assert_not @deck.notes.new(front: "", back: "b").valid?
      assert_not @deck.notes.new(front: "a", back: "b", note_type: "cloze").valid?
      assert @deck.notes.new(front: "a", back: "b").valid?
    end

    test "Básico gera um cartão e Básico + invertido gera dois" do
      basic = @deck.notes.create!(front: "dog", back: "cachorro")
      assert_equal [ 0 ], basic.cards.map(&:ordinal)

      reversed = @deck.notes.create!(front: "cat", back: "gato", note_type: "basic_reversed")
      assert_equal [ 0, 1 ], reversed.cards.map(&:ordinal)
      assert_equal "gato", reversed.cards.last.question
      assert_equal "cat", reversed.cards.last.answer
    end

    test "trocar o tipo cria ou remove só o cartão invertido" do
      note = @deck.notes.create!(front: "dog", back: "cachorro", note_type: "basic_reversed")
      front_card = note.cards.first
      front_card.answer!(4)

      note.update!(note_type: "basic")
      assert_equal [ front_card.id ], note.cards.map(&:id)
      assert_equal "review", front_card.reload.state
      assert_equal 1, front_card.reviews.count

      note.update!(note_type: "basic_reversed")
      assert_equal [ 0, 1 ], note.cards.map(&:ordinal)
      assert_equal front_card.id, note.cards.first.id
    end

    test "recomeçar volta os cartões a novos e mantém o histórico" do
      note = @deck.notes.create!(front: "dog", back: "cachorro")
      card = note.cards.first
      card.answer!(4)

      note.reset!
      card.reload
      assert_equal [ "new", nil, 0 ], [ card.state, card.due_at, card.interval_days ]
      assert_equal 1, card.reviews.count
    end

    test "busca por trecho da frente, do verso e das tags" do
      dog = @deck.notes.create!(front: "dog", back: "cachorro", tags: "Animais")
      @deck.notes.create!(front: "table", back: "mesa")

      assert_equal [ dog ], Note.search("cachor").to_a
      assert_equal [ dog ], Note.search("animais").to_a
      assert_equal [ dog ], Note.with_tag("animais").to_a
    end

    test "apagar o baralho apaga notas, cartões e revisões" do
      note = @deck.notes.create!(front: "dog", back: "cachorro")
      note.cards.first.answer!(3)

      @deck.destroy
      assert_equal 0, Note.count
      assert_equal 0, Card.count
      assert_equal 0, Review.count
    end
  end
end
