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

    test "ordem: fazendo, a fazer e concluídas, cada coluna na ordem do quadro" do
      todo_a = @initiative.tasks.create!(title: "a", due_on: "2026-12-10")
      todo_b = @initiative.tasks.create!(title: "b")
      doing = @initiative.tasks.create!(title: "d", status: "doing")
      done = @initiative.tasks.create!(title: "e", status: "done")

      assert_equal [ doing, todo_a, todo_b, done ], @initiative.tasks.ordered.to_a
      assert_equal [ 0, 1 ], [ todo_a.position, todo_b.position ]
    end

    test "numera as tarefas dentro de cada iniciativa" do
      other = Initiative.create!(name: "Outra")
      first = @initiative.tasks.create!(title: "a")
      second = @initiative.tasks.create!(title: "b")
      foreign = other.tasks.create!(title: "c")

      assert_equal [ 1, 2, 1 ], [ first.number, second.number, foreign.number ]
      second.destroy
      assert_equal 3, @initiative.tasks.create!(title: "d").number
    end

    test "mudar de status leva a tarefa para o fim da nova coluna" do
      a = @initiative.tasks.create!(title: "a")
      b = @initiative.tasks.create!(title: "b", status: "doing")
      a.update!(status: "doing")

      assert_equal [ b, a ], @initiative.tasks.doing.order(:position).to_a
    end

    test "move_to muda a coluna, a posição e renumera a coluna" do
      a, b, c = %w[a b c].map { |t| @initiative.tasks.create!(title: t) }
      d = @initiative.tasks.create!(title: "d", status: "doing")

      c.move_to("todo", index: 0)
      assert_equal [ c, a, b ], @initiative.tasks.todo.order(:position).to_a
      assert_equal [ 0, 1, 2 ], @initiative.tasks.todo.order(:position).pluck(:position)

      a.move_to("doing", index: 0)
      assert_equal [ a, d ], @initiative.tasks.doing.order(:position).to_a
      assert_equal "doing", a.reload.status

      b.move_to("doing", before_id: d.id)
      assert_equal [ a, b, d ], @initiative.tasks.doing.order(:position).to_a

      c.move_to("done")
      assert_not_nil c.reload.completed_at
      c.move_to("todo", index: 99)
      assert_nil c.reload.completed_at
      assert_equal [ c ], @initiative.tasks.todo.to_a
    end

    test "a descrição é sanitizada e o texto puro alimenta a busca" do
      task = @initiative.tasks.create!(
        title: "x",
        description: '<p style="color:red" onclick="x()"><font face="Arial">Olá <strong>mundo</strong></font></p>' \
                     '<script>alert(1)</script><style>p { color: red }</style><img src="a.png">' \
                     '<ul><li><a href="javascript:alert(1)">ruim</a> <a href="https://exemplo.com">bom</a></li></ul>'
      )

      assert_includes task.description, "<p>Olá <strong>mundo</strong></p>"
      assert_includes task.description, '<a href="https://exemplo.com">bom</a>'
      %w[style onclick font script img javascript alert].each { |bad| assert_not_includes task.description, bad }
      assert_equal "Olá mundo\nruim bom", task.description_text
      assert_includes Task.search("mundo"), task
      assert_not_includes Task.search("strong"), task
      assert_not_includes Task.search("alert"), task
    end

    test "descrição em texto puro vira parágrafos e vazia vira nil" do
      task = @initiative.tasks.create!(title: "x", description: "Linha 1\nLinha 2\n\nOutro <3 & mais")

      assert_equal "<p>Linha 1<br>Linha 2</p><p>Outro &lt;3 &amp; mais</p>", task.description
      assert_equal "Linha 1\nLinha 2\nOutro <3 & mais", task.description_text.gsub("\n\n", "\n")

      task.update!(description: "<p></p>")
      assert_nil task.description
      assert_nil task.description_text
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
