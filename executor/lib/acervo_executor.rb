require "erb"
require "fileutils"
require "json"
require "net/http"
require "open3"
require "time"
require "tmpdir"
require "uri"
require "yaml"

module AcervoExecutor
  VERSION = "1.0.0".freeze
  class Error < StandardError; end
end

require_relative "acervo_executor/shell"
require_relative "acervo_executor/config"
require_relative "acervo_executor/log"
require_relative "acervo_executor/client"
require_relative "acervo_executor/spool"
require_relative "acervo_executor/workspace"
require_relative "acervo_executor/prompt"
require_relative "acervo_executor/agent"
require_relative "acervo_executor/publisher"
require_relative "acervo_executor/repository_checker"
require_relative "acervo_executor/loop"
require_relative "acervo_executor/cli"
