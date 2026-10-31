require "test_helper"

module Initiatives
  class TaskTest < ActiveSupport::TestCase
    setup { @initiative = Initiative.create!(name: "Jogo") }

    test "só o título é obrigatório e os padrões são aplicados" do
      task = @initiative.tasks.create!(title: " Movimento ")

      assert_equal "Movimento", task.title
      assert_equal "todo", task.status
      assert_equal "medium", task.priority
      assert_not @initiative.tasks.new(title: "").valid?
      assert_not @initiative.tasks.new(title: "a" * 301).valid?
    end

    test "status e prioridade fora da lista são recusados" do
      assert @initiative.tasks.new(title: "x", status: "blocked").invalid?
      assert @initiative.tasks.new(title: "x", priority: "urgent").invalid?
    end

    test "concluir grava a data e reabrir limpa" do
      task = @initiative.tasks.create!(title: "x")
      assert_nil task.completed_at

      task.update!(status: "done")
      assert_not_nil task.completed_at

      task.update!(status: "doing")
      assert_nil task.completed_at
    end

    test "marco precisa ser da mesma iniciativa" do
      other = Initiative.create!(name: "Outra")
      foreign = other.milestones.create!(title: "m")
      own = @initiative.milestones.create!(title: "m")

      assert @initiative.tasks.new(title: "x", milestone: own).valid?
      task = @initiative.tasks.new(title: "x", milestone_id: foreign.id)
      assert task.invalid?
      assert task.errors[:milestone_id].any?
      assert @initiative.tasks.new(title: "x", milestone_id: 0).invalid?
    end

    test "ordem: fazendo, a fazer por prazo e concluídas mais recentes primeiro" do
      todo_late = @initiative.tasks.create!(title: "a", due_on: "2026-12-10")
      todo_undated = @initiative.tasks.create!(title: "b")
      todo_soon = @initiative.tasks.create!(title: "c", due_on: "2026-11-05")
      doing = @initiative.tasks.create!(title: "d", status: "doing")
      done_old = @initiative.tasks.create!(title: "e", status: "done")
      done_new = @initiative.tasks.create!(title: "f", status: "done")
      done_old.update_column(:completed_at, 2.days.ago)

      assert_equal [ doing, todo_soon, todo_late, todo_undated, done_new, done_old ], @initiative.tasks.ordered.to_a
    end

    test "atrasada quando não concluída e com prazo passado" do
      assert @initiative.tasks.new(title: "x", due_on: Date.yesterday).overdue?
      assert_not @initiative.tasks.new(title: "x", due_on: Date.yesterday, status: "done").overdue?
      assert_not @initiative.tasks.new(title: "x").overdue?
    end

    test "alterar a tarefa atualiza a iniciativa" do
      @initiative.update_column(:updated_at, 1.day.ago)
      before = @initiative.reload.updated_at

      @initiative.tasks.create!(title: "x")
      assert_operator @initiative.reload.updated_at, :>, before
    end

    test "busca por palavra e por pedaço" do
      found = @initiative.tasks.create!(title: "Movimento do personagem", description: "usar CharacterBody2D")
      @initiative.tasks.create!(title: "Menu inicial")

      assert_equal [ found ], @initiative.tasks.search("personagem").to_a
      assert_equal [ found ], @initiative.tasks.search("CharacterBo").to_a
    end
  end
end
