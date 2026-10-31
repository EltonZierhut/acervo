require "test_helper"

module Initiatives
  class InitiativeTest < ActiveSupport::TestCase
    test "só o nome é obrigatório e os padrões são aplicados" do
      initiative = Initiative.create!(name: "  Jogo para a Steam ")

      assert_equal "Jogo para a Steam", initiative.name
      assert_equal "planned", initiative.status
      assert_equal "medium", initiative.priority
      assert_equal Initiative::SECTIONS, initiative.reload.sections
      assert_equal [], initiative.tags
      assert_nil initiative.description
    end

    test "nome vazio ou longo demais é recusado" do
      assert_not Initiative.new(name: " ").valid?
      assert_not Initiative.new(name: "a" * 201).valid?
    end

    test "status, prioridade e seções fora da lista são recusados" do
      assert Initiative.new(name: "x", status: "bogus").invalid?
      assert Initiative.new(name: "x", priority: "urgent").invalid?

      initiative = Initiative.new(name: "x", sections: %w[tasks decisions])
      assert initiative.invalid?
      assert initiative.errors[:sections].any?
    end

    test "seções ficam na ordem padrão, sem repetição, e podem ficar vazias" do
      assert_equal %w[tasks milestones], Initiative.new(sections: %w[milestones tasks tasks]).sections
      assert_equal [], Initiative.create!(name: "x", sections: []).reload.sections
    end

    test "data-alvo não pode ser anterior ao início" do
      assert Initiative.new(name: "x", starts_on: "2026-11-10", due_on: "2026-11-10").valid?
      initiative = Initiative.new(name: "x", starts_on: "2026-11-10", due_on: "2026-11-01")
      assert initiative.invalid?
      assert initiative.errors[:due_on].any?
    end

    test "contexto inexistente é recusado" do
      initiative = Initiative.new(name: "x", context_id: 0)
      assert initiative.invalid?
      assert initiative.errors[:context_id].any?
    end

    test "rejeita caractere nulo" do
      assert Initiative.new(name: "a\u0000b").invalid?
    end

    test "tags aceitam texto" do
      assert_equal %w[godot steam], Initiative.new(name: "x", tags: "Godot, steam").tags
    end

    test "ordem: ativas primeiro e depois as alteradas recentemente" do
      old_active = Initiative.create!(name: "a", status: "active")
      paused = Initiative.create!(name: "b", status: "paused")
      new_active = Initiative.create!(name: "c", status: "active")
      planned = Initiative.create!(name: "d")
      old_active.update_column(:updated_at, 1.day.ago)

      assert_equal [ new_active, old_active, planned, paused ], Initiative.ordered.to_a
    end

    test "busca por palavra e por pedaço de tag" do
      found = Initiative.create!(name: "Jogo para a Steam", tags: "godot")
      Initiative.create!(name: "Reforma da cozinha")

      assert_equal [ found ], Initiative.search("Steam").to_a
      assert_equal [ found ], Initiative.search("odo").to_a
    end

    test "progresso conta tarefas concluídas e o total" do
      initiative = Initiative.create!(name: "x")
      empty = Initiative.create!(name: "y")
      initiative.tasks.create!(title: "a", status: "done")
      initiative.tasks.create!(title: "b")

      progress = Initiative.progress_for([ initiative.id, empty.id ])
      assert_equal({ done: 1, total: 2 }, progress[initiative.id])
      assert_nil progress[empty.id]
    end

    test "apagar a iniciativa apaga marcos e tarefas" do
      initiative = Initiative.create!(name: "x")
      milestone = initiative.milestones.create!(title: "m")
      initiative.tasks.create!(title: "t", milestone:)

      assert_difference -> { Task.count } => -1, -> { Milestone.count } => -1 do
        initiative.destroy
      end
    end
  end
end
