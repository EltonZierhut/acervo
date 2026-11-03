require "test_helper"

module Brag
  class EntryTest < ActiveSupport::TestCase
    test "título e data são obrigatórios" do
      assert Entry.new(title: "a", achieved_on: Date.current).valid?
      assert_not Entry.new(title: "a").valid?
      assert_not Entry.new(achieved_on: Date.current).valid?
    end

    test "campos opcionais em branco viram nulos" do
      entry = Entry.create!(title: "a", achieved_on: Date.current, category: " ", description: "", project: "")
      assert_nil entry.reload.category
      assert_nil entry.description
      assert_nil entry.project
    end
  end
end
