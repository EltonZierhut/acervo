module AcervoExecutor
  # Comandos externos, sempre como lista de argumentos, nunca por um shell.
  class Shell
    Result = Struct.new(:stdout, :stderr, :success) do
      def ok? = success
    end

    def run(*argv, chdir: nil, env: {})
      options = chdir ? { chdir: } : {}
      stdout, stderr, status = Open3.capture3(env, *argv, **options)
      Result.new(stdout, stderr, status.success?)
    rescue SystemCallError => e
      Result.new("", e.message, false)
    end
  end
end
