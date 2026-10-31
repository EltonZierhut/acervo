require "test_helper"

module Initiatives
  class ContextTest < ActiveSupport::TestCase
    test "nome é obrigatório e tem limite" do
      assert Context.new(name: "Trabalho").valid?
      assert_not Context.new(name: "  ").valid?
      assert_not Context.new(name: "a" * 61).valid?
    end

    test "nome é único sem diferenciar maiúsculas" do
      Context.create!(name: "Trabalho")
      context = Context.new(name: " trabalho ")
      assert_not context.valid?
      assert context.errors[:name].any?
    end

    test "cor tem padrão e precisa ser hexadecimal" do
      assert_equal Context::DEFAULT_COLOR, Context.create!(name: "Casa").color
      assert_equal "#aabbcc", Context.create!(name: "Jogo", color: " #AABBCC ").color
      assert_not Context.new(name: "X", color: "azul").valid?
      assert_not Context.new(name: "X", color: "#abc").valid?
    end

    test "apagar o contexto mantém as iniciativas" do
      context = Context.create!(name: "Casa")
      initiative = Initiative.create!(name: "Reforma", context:)

      context.destroy
      assert_nil initiative.reload.context_id
    end
  end
end
