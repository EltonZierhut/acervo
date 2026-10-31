ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Processo único: o rate_limit usa cache em memória.
    parallelize(workers: 1)

    fixtures :all

    setup { Rails.cache.clear }
  end
end

module SignInHelper
  TEST_PASSWORD = "senha-de-teste-123".freeze

  def sign_in_as(user, password: TEST_PASSWORD)
    post api_v1_session_path, params: { email_address: user.email_address, password: }, as: :json
    assert_response :created, "login falhou para #{user.email_address}"
  end

  def json
    response.parsed_body
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
