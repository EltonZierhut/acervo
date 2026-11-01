require "minitest/autorun"
require "acervo_executor"

ENV["ACERVO_EXECUTOR_STATE"] = Dir.mktmpdir("acervo-state-")

module TestSupport
  def config(extra = {})
    AcervoExecutor::Config.new({ "api_url" => "https://acervo.test", "executor_token" => "tok-exec",
                                 "claude_oauth_token" => "tok-claude" }.merge(extra))
  end

  def quiet_log = AcervoExecutor::Log.new(secrets: %w[tok-exec tok-claude], io: StringIO.new)

  def git(dir, *args)
    out, status = Open3.capture2e("git", "-C", dir, *args)
    raise out unless status.success?

    out
  end

  # Repositório local com um remoto "origin" num bare, para testar git de verdade.
  def with_repo
    Dir.mktmpdir do |root|
      bare = File.join(root, "origin.git")
      repo = File.join(root, "repo")
      system("git", "init", "-q", "--bare", "-b", "main", bare, exception: true)
      system("git", "init", "-q", "-b", "main", repo, exception: true)
      git(repo, "config", "user.email", "t@e.st")
      git(repo, "config", "user.name", "Teste")
      File.write(File.join(repo, "a.txt"), "a\n")
      git(repo, "add", "-A")
      git(repo, "commit", "-qm", "inicial")
      git(repo, "remote", "add", "origin", bare)
      git(repo, "push", "-q", "origin", "main")
      yield repo, bare, root
    end
  end
end
