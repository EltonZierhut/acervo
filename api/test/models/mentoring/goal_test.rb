require "test_helper"

module Mentoring
  class GoalTest < ActiveSupport::TestCase
    setup { @mentorship = Mentorship.create!(mentor_name: "Ana") }

    test "começa não iniciado com 0% e valida progresso e situação" do
      goal = @mentorship.goals.create!(title: "Delegar mais")
      assert_equal [ "not_started", 0 ], [ goal.status, goal.progress ]
      assert_not @mentorship.goals.new(title: "x", progress: 101).valid?
      assert_not @mentorship.goals.new(title: "x", status: "late").valid?
      assert_not @mentorship.goals.new(title: "").valid?
    end

    test "progresso acima de 0 coloca em andamento e alcançado força 100" do
      goal = @mentorship.goals.create!(title: "Delegar mais")
      goal.update!(progress: 30)
      assert_equal "in_progress", goal.status
      goal.update!(status: "achieved")
      assert_equal 100, goal.progress
    end

    test "atrasado é prazo vencido sem estar alcançado ou abandonado" do
      assert @mentorship.goals.create!(title: "a", target_on: Date.current - 1).overdue?
      assert_not @mentorship.goals.create!(title: "b", target_on: Date.current).overdue?
      assert_not @mentorship.goals.create!(title: "c", target_on: Date.current - 1, status: "achieved").overdue?
      assert_not @mentorship.goals.create!(title: "d", target_on: Date.current - 1, status: "dropped").overdue?
    end

    test "ordem: abertos por prazo, depois alcançados e abandonados" do
      dropped = @mentorship.goals.create!(title: "d", status: "dropped")
      achieved = @mentorship.goals.create!(title: "c", status: "achieved")
      no_date = @mentorship.goals.create!(title: "b")
      soon = @mentorship.goals.create!(title: "a", target_on: Date.current + 3)
      assert_equal [ soon, no_date, achieved, dropped ], @mentorship.goals.ordered.to_a
    end
  end
end
