require "test_helper"

module Initiatives
  class MilestoneTest < ActiveSupport::TestCase
    setup { @initiative = Initiative.create!(name: "Jogo") }

    test "título é obrigatório" do
      assert @initiative.milestones.new(title: "Protótipo").valid?
      assert_not @initiative.milestones.new(title: " ").valid?
      assert_not @initiative.milestones.new(title: "a" * 201).valid?
    end

    test "completed grava e limpa a data de conclusão" do
      milestone = @initiative.milestones.create!(title: "m")
      assert_not milestone.completed?

      milestone.update!(completed: true)
      completed_at = milestone.completed_at
      assert milestone.completed?

      milestone.update!(completed: "true")
      assert_equal completed_at, milestone.completed_at

      milestone.update!(completed: false)
      assert_nil milestone.completed_at
    end

    test "ordem pela data-alvo, sem data por último" do
      late = @initiative.milestones.create!(title: "b", due_on: "2027-02-01")
      undated = @initiative.milestones.create!(title: "c")
      early = @initiative.milestones.create!(title: "a", due_on: "2026-12-01")

      assert_equal [ early, late, undated ], @initiative.milestones.ordered.to_a
    end

    test "atrasado quando não concluído e com data passada" do
      assert @initiative.milestones.new(title: "m", due_on: Date.yesterday).overdue?
      assert_not @initiative.milestones.new(title: "m", due_on: Date.current).overdue?
      assert_not @initiative.milestones.new(title: "m", due_on: Date.yesterday, completed: true).overdue?
    end

    test "progresso das tarefas ligadas" do
      milestone = @initiative.milestones.create!(title: "m")
      @initiative.tasks.create!(title: "a", milestone:, status: "done")
      @initiative.tasks.create!(title: "b", milestone:)
      @initiative.tasks.create!(title: "c")

      assert_equal({ done: 1, total: 2 }, Milestone.progress_for([ milestone.id ])[milestone.id])
    end

    test "apagar o marco mantém as tarefas sem marco" do
      milestone = @initiative.milestones.create!(title: "m")
      task = @initiative.tasks.create!(title: "a", milestone:)

      milestone.destroy
      assert_nil task.reload.milestone_id
    end
  end
end
