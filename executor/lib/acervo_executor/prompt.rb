module AcervoExecutor
  module Prompt
    TEMPLATE = File.expand_path("../../prompts/task.md.erb", __dir__)

    def self.render(run, image_paths:, pr_template:)
      binding_values = {
        task_title: run.dig("task", "title"),
        task_description: run.dig("task", "description"),
        links: run.fetch("links", []),
        questions: run.fetch("questions", []),
        image_paths:,
        pr_template:
      }
      ERB.new(File.read(TEMPLATE), trim_mode: nil).result_with_hash(binding_values)
    end
  end
end
