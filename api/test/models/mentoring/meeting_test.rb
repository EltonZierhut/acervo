require "test_helper"

module Mentoring
  class MeetingTest < ActiveSupport::TestCase
    setup { @mentorship = Mentorship.create!(mentor_name: "Ana") }

    test "vem com a data de hoje e nota opcional de 1 a 5" do
      meeting = @mentorship.meetings.create!
      assert_equal Date.current, meeting.held_on
      assert_nil meeting.rating
      assert_not @mentorship.meetings.new(rating: 6).valid?
      assert_not @mentorship.meetings.new(rating: 0).valid?
    end

    test "busca na pauta, anotações, aprendizados e tags" do
      planning = @mentorship.meetings.create!(agenda: "Plano de carreira", tags: "Carreira")
      feedback = @mentorship.meetings.create!(notes: "Conversa sobre feedback difícil", takeaways: "Usar SBI")

      assert_equal [ planning ], @mentorship.meetings.search("carreira").to_a
      assert_equal [ feedback ], @mentorship.meetings.search("SBI").to_a
      assert_equal [ feedback ], @mentorship.meetings.search("difíc").to_a
    end

    test "apagar o encontro mantém as ações, sem o vínculo" do
      meeting = @mentorship.meetings.create!
      item = @mentorship.action_items.create!(title: "Ler", meeting:)
      meeting.destroy
      assert_nil item.reload.meeting_id
    end
  end
end
