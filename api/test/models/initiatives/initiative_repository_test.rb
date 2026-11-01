require "test_helper"

class Initiatives::InitiativeRepositoryTest < ActiveSupport::TestCase
  def build(value) = Initiatives::Initiative.new(name: "I", github_repository: value)

  test "normaliza endereços do GitHub" do
    %w[owner/name https://github.com/owner/name https://github.com/owner/name.git
       https://github.com/owner/name/ git@github.com:owner/name.git].each do |value|
      assert_equal "owner/name", build(value).github_repository, value
    end
  end

  test "vazio remove a conexão" do
    assert_nil build("  ").github_repository
  end

  test "recusa formatos inválidos" do
    %w[owner owner/name/extra https://gitlab.com/owner/name -owner/name owner/.. ../x].each do |value|
      assert_not build(value).valid?, value
    end
  end

  test "trocar o repositório volta para não verificado" do
    initiative = Initiatives::Initiative.create!(name: "I", github_repository: "a/b")
    initiative.update!(repository_status: :invalid, repository_error: "x", repository_checked_at: Time.current)
    initiative.update!(github_repository: "a/c")
    assert initiative.repository_unverified?
    assert_nil initiative.repository_error
    assert_nil initiative.repository_checked_at
  end

  test "outras alterações não mexem na verificação" do
    initiative = Initiatives::Initiative.create!(name: "I", github_repository: "a/b")
    initiative.update!(repository_status: :valid)
    initiative.update!(name: "Outro")
    assert initiative.repository_valid?
  end
end
