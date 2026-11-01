require "test_helper"

class Initiatives::TaskLinkTest < ActiveSupport::TestCase
  setup { @task = Initiatives::Initiative.create!(name: "I").tasks.create!(title: "T") }

  test "aceita http e https" do
    assert @task.links.new(url: " https://example.com/a ").valid?
    assert @task.links.new(url: "http://example.com").valid?
  end

  test "recusa outros esquemas e endereços inválidos" do
    %w[javascript:alert(1) ftp://example.com file:///etc/passwd https:// isso\ não].each do |url|
      assert_not @task.links.new(url:).valid?, url
    end
  end

  test "limita url e título" do
    assert_not @task.links.new(url: "https://e.com/#{'a' * 2_048}").valid?
    assert_not @task.links.new(url: "https://e.com", title: "a" * 201).valid?
  end
end
