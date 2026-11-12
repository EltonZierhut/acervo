require "test_helper"

module Mentoring
  class MentorshipTest < ActiveSupport::TestCase
    test "só o nome do mentor é obrigatório; começa ativa e hoje" do
      assert_not Mentorship.new(mentor_name: "  ").valid?
      mentorship = Mentorship.create!(mentor_name: " Ana ")
      assert_equal "Ana", mentorship.mentor_name
      assert_equal "active", mentorship.status
      assert_equal Date.current, mentorship.started_on
    end

    test "situação precisa ser válida e o término não pode vir antes do início" do
      assert_not Mentorship.new(mentor_name: "Ana", status: "cancelled").valid?
      mentorship = Mentorship.new(mentor_name: "Ana", started_on: "2026-05-10", ended_on: "2026-05-01")
      assert_not mentorship.valid?
      assert mentorship.errors.key?(:ended_on)
    end

    test "perguntas sugeridas entram em ordem" do
      mentorship = Mentorship.create!(mentor_name: "Ana")
      mentorship.add_suggested_questions!
      assert_equal SuggestedQuestions::ALL, mentorship.questions.map(&:prompt)
      assert_equal (1..SuggestedQuestions::ALL.size).to_a, mentorship.questions.map(&:position)
    end

    test "lista ativas, depois pausadas e encerradas" do
      finished = Mentorship.create!(mentor_name: "C", status: "finished", started_on: "2026-10-01")
      paused = Mentorship.create!(mentor_name: "B", status: "paused", started_on: "2026-09-01")
      old_active = Mentorship.create!(mentor_name: "A", started_on: "2025-01-01")
      new_active = Mentorship.create!(mentor_name: "D", started_on: "2026-11-01")
      assert_equal [ new_active, old_active, paused, finished ], Mentorship.listed.to_a
    end

    test "apagar a mentoria apaga tudo dela" do
      mentorship = Mentorship.create!(mentor_name: "Ana")
      mentorship.add_suggested_questions!
      goal = mentorship.goals.create!(title: "Falar em público")
      meeting = mentorship.meetings.create!
      mentorship.action_items.create!(title: "Ler livro", goal:, meeting:)
      mentorship.competencies.create!(name: "Comunicação").ratings.create!(rated_on: Date.current, score: 3)

      mentorship.destroy
      assert_equal 0, Question.count + Goal.count + Meeting.count + ActionItem.count + Competency.count + Rating.count
    end
  end
end
