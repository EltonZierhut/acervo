require "test_helper"

module Codes
  class SnippetTest < ActiveSupport::TestCase
    test "só o conteúdo é obrigatório" do
      assert Snippet.new(content: "ls").valid?
      assert_not Snippet.new(content: "  \n ").valid?
    end

    test "conteúdo é guardado sem alteração" do
      content = "\n  if true; then\n\techo \"$HOME\" 'é' \\\n\n  fi\n\n"
      assert_equal content, Snippet.create!(content:).reload.content
    end

    test "título em branco vira nulo e tem limite" do
      assert_nil Snippet.create!(title: "  ", content: "ls").reload.title
      assert_not Snippet.new(title: "a" * 201, content: "ls").valid?
    end

    test "display_title usa o título ou a primeira linha com texto" do
      assert_equal "Backup", Snippet.new(title: "Backup", content: "ls").display_title
      assert_equal "pg_dump x", Snippet.new(content: "\n  \n  pg_dump x  \nls").display_title
      assert_equal 200, Snippet.new(content: "a" * 500).display_title.length
    end

    test "conteúdo tem limite de 1 MB" do
      assert Snippet.new(content: "a" * Snippet::CONTENT_MAX_BYTES).valid?
      assert_not Snippet.new(content: "a" * (Snippet::CONTENT_MAX_BYTES + 1)).valid?
      assert_not Snippet.new(content: "é" * (Snippet::CONTENT_MAX_BYTES / 2 + 1)).valid?
    end

    test "rejeita caractere nulo" do
      assert_not Snippet.new(content: "a\u0000b").valid?
    end

    test "tags aceitam texto ou array" do
      assert_equal %w[react hooks], Snippet.new(content: "x", tags: "React, hooks, react").tags
      assert_equal %w[a b], Snippet.new(content: "x", tags: [ "A", " b ", "" ]).tags
      assert_equal [], Snippet.new(content: "x", tags: "").tags
      assert_equal [], Snippet.new(content: "x", tags: nil).tags
    end
  end
end
