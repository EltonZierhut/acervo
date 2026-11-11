require "test_helper"

module Mentoring
  class QuestionTest < ActiveSupport::TestCase
    setup { @mentorship = Mentorship.create!(mentor_name: "Ana") }

    test "texto é obrigatório e respondida é ter resposta não vazia" do
      assert_not @mentorship.questions.new(prompt: " ").valid?
      question = @mentorship.questions.create!(prompt: "Objetivo?")
      assert_not question.answered?
      question.update!(answer: "   ")
      assert_nil question.answer
      question.update!(answer: "Liderar um time")
      assert question.answered?
      assert_equal [ question ], @mentorship.questions.answered.to_a
    end

    test "nova pergunta entra no fim" do
      first = @mentorship.questions.create!(prompt: "A")
      second = @mentorship.questions.create!(prompt: "B")
      assert_equal [ 1, 2 ], [ first.position, second.position ]
    end

    test "sobe e desce trocando com a vizinha; nas pontas não muda" do
      a, b, c = %w[A B C].map { |prompt| @mentorship.questions.create!(prompt:) }

      assert c.move!(:up)
      assert_equal %w[A C B], @mentorship.questions.reload.map(&:prompt)
      assert_not a.reload.move!(:up)
      assert b.reload.move!(:down) == false
      assert a.reload.move!(:down)
      assert_equal %w[C A B], @mentorship.questions.reload.map(&:prompt)
      assert_equal [ 1, 2, 3 ], @mentorship.questions.map(&:position)
    end
  end
end
