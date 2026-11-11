require "test_helper"

module Mentoring
  class ActionItemTest < ActiveSupport::TestCase
    setup { @mentorship = Mentorship.create!(mentor_name: "Ana") }

    test "concluir guarda a data e desmarcar reabre" do
      item = @mentorship.action_items.create!(title: "Ler livro")
      assert_not item.done?
      item.update!(done: true)
      assert item.completed_at.present?
      item.update!(done: "false")
      assert_nil item.completed_at
    end

    test "encontro e objetivo precisam ser da mesma mentoria" do
      other = Mentorship.create!(mentor_name: "Bia")
      item = @mentorship.action_items.new(title: "x", goal: other.goals.create!(title: "g"), meeting: other.meetings.create!)
      assert_not item.valid?
      assert item.errors.key?(:goal)
      assert item.errors.key?(:meeting)
    end

    test "atrasada é aberta com prazo antes de hoje" do
      late = @mentorship.action_items.create!(title: "a", due_on: Date.current - 1)
      @mentorship.action_items.create!(title: "b", due_on: Date.current)
      @mentorship.action_items.create!(title: "c", due_on: Date.current - 2, done: true)
      assert late.overdue?
      assert_equal [ late ], @mentorship.action_items.overdue.to_a
    end

    test "ordem: abertas por prazo, sem prazo no fim, depois concluídas recentes" do
      no_date = @mentorship.action_items.create!(title: "sem prazo")
      later = @mentorship.action_items.create!(title: "depois", due_on: Date.current + 5)
      sooner = @mentorship.action_items.create!(title: "antes", due_on: Date.current + 1)
      done_old = @mentorship.action_items.create!(title: "feita antes", completed_at: 2.days.ago)
      done_new = @mentorship.action_items.create!(title: "feita agora", completed_at: 1.hour.ago)
      assert_equal [ sooner, later, no_date, done_new, done_old ], @mentorship.action_items.ordered.to_a
    end

    test "apagar o objetivo mantém a ação" do
      goal = @mentorship.goals.create!(title: "g")
      item = @mentorship.action_items.create!(title: "x", goal:)
      goal.destroy
      assert_nil item.reload.goal_id
    end
  end
end
