require "test_helper"
require "rake"

class AcervoExecutorTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("acervo:executor:create")
    Rake::Task["acervo:executor:create"].reenable
  end

  test "mostra um token válido, que não fica guardado" do
    output, = capture_io { Rake::Task["acervo:executor:create"].invoke }
    token = output.lines.last.strip
    assert Initiatives::Executor.authenticate(token)
    assert_not_equal token, Initiatives::Executor.first.token_digest
  end
end
