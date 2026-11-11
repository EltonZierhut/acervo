require "test_helper"

module Mentoring
  class OverviewTest < ActiveSupport::TestCase
    setup do
      @mentorship = Mentorship.create!(mentor_name: "Ana")
      @today = Date.new(2026, 11, 11)
    end

    def overview
      Overview.new(@mentorship, today: @today).to_h
    end

    test "mentoria vazia" do
      result = overview
      assert_equal({ total: 0, answered: 0 }, result[:questions])
      assert_equal({ total: 0, achieved: 0, average_progress: nil }, result[:goals])
      assert_equal({ total: 0, done: 0, overdue: 0, next: [] }, result[:action_items])
      assert_equal({ held: 0, last_held_on: nil, days_since_last: nil, next_on: nil, average_rating: nil }, result[:meetings])
      assert_equal({ total: 0, assessments: 0, average_delta: nil }, result[:competencies])
    end

    test "questionário: respondidas de total" do
      @mentorship.questions.create!(prompt: "A", answer: "sim")
      @mentorship.questions.create!(prompt: "B")
      assert_equal({ total: 2, answered: 1 }, overview[:questions])
    end

    test "objetivos: média sem os abandonados e alcançados" do
      @mentorship.goals.create!(title: "a", status: "achieved")
      @mentorship.goals.create!(title: "b", progress: 25)
      @mentorship.goals.create!(title: "c", progress: 90, status: "dropped")
      assert_equal({ total: 2, achieved: 1, average_progress: 63 }, overview[:goals])
    end

    test "ações: concluídas, atrasadas e as próximas cinco por prazo" do
      7.times { |i| @mentorship.action_items.create!(title: "a#{i}", due_on: @today + i - 1) }
      @mentorship.action_items.create!(title: "feita", due_on: @today - 5, done: true)

      result = overview[:action_items]
      assert_equal [ 8, 1, 1 ], result.values_at(:total, :done, :overdue)
      assert_equal %w[a0 a1 a2 a3 a4], result[:next].map(&:title)
    end

    test "encontros: realizados, último, dias desde ele, próximo agendado e nota média" do
      @mentorship.meetings.create!(held_on: @today - 20, rating: 4)
      @mentorship.meetings.create!(held_on: @today - 6, rating: 5)
      @mentorship.meetings.create!(held_on: @today - 3)
      @mentorship.meetings.create!(held_on: @today + 7, rating: 1)

      assert_equal({ held: 3, last_held_on: @today - 3, days_since_last: 3, next_on: @today + 7, average_rating: 4.5 },
                   overview[:meetings])
    end

    test "competências: autoavaliações e evolução média" do
      a = @mentorship.competencies.create!(name: "A")
      b = @mentorship.competencies.create!(name: "B")
      @mentorship.competencies.create!(name: "C")
      Assessments.new(@mentorship).save!(rated_on: "2026-09-01", entries: [ { competency_id: a.id, score: 1 },
                                                                         { competency_id: b.id, score: 3 } ])
      Assessments.new(@mentorship).save!(rated_on: "2026-11-01", entries: [ { competency_id: a.id, score: 4 },
                                                                         { competency_id: b.id, score: 3 } ])
      assert_equal({ total: 3, assessments: 2, average_delta: 1.5 }, overview[:competencies])
    end

    test "resumo da lista" do
      @mentorship.goals.create!(title: "a")
      @mentorship.goals.create!(title: "b", status: "achieved")
      @mentorship.action_items.create!(title: "x")
      @mentorship.meetings.create!(held_on: @today - 2)
      @mentorship.meetings.create!(held_on: @today + 2)
      empty = Mentorship.create!(mentor_name: "Bia")

      summaries = Overview.summaries([ @mentorship, empty ], today: @today)
      assert_equal({ goals_open: 1, goals_achieved: 1, action_items_open: 1, last_meeting_on: @today - 2 }, summaries[@mentorship.id])
      assert_equal({ goals_open: 0, goals_achieved: 0, action_items_open: 0, last_meeting_on: nil }, summaries[empty.id])
    end
  end
end
