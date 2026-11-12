require "test_helper"

module Mentoring
  class AssessmentsTest < ActiveSupport::TestCase
    setup do
      @mentorship = Mentorship.create!(mentor_name: "Ana")
      @communication = @mentorship.competencies.create!(name: "Comunicação")
      @delegation = @mentorship.competencies.create!(name: "Delegação")
      @assessments = Assessments.new(@mentorship)
    end

    test "nome da competência é único na mentoria, sem diferenciar maiúsculas" do
      assert_not @mentorship.competencies.new(name: "comunicação").valid?
      assert Mentorship.create!(mentor_name: "Bia").competencies.new(name: "Comunicação").valid?
      assert_equal [ 1, 2 ], [ @communication.position, @delegation.position ]
    end

    test "primeira, última e variação por competência" do
      @assessments.save!(rated_on: "2026-09-01", entries: [ { competency_id: @communication.id, score: 2 },
                                                            { competency_id: @delegation.id, score: 3 } ])
      @assessments.save!(rated_on: "2026-11-01", entries: [ { competency_id: @communication.id, score: 4 },
                                                            { competency_id: @delegation.id, score: 3, comment: "igual" } ])

      result = @assessments.to_h
      assert_equal [ Date.new(2026, 9, 1), Date.new(2026, 11, 1) ], result[:dates]
      communication, delegation = result[:competencies]
      assert_equal [ 2, 4, 2 ], communication.values_at(:first, :last, :delta)
      assert_equal [ 3, 3, 0 ], delegation.values_at(:first, :last, :delta)
      assert_equal "igual", delegation[:ratings].last[:comment]
    end

    test "salvar de novo na mesma data substitui; nota vazia apaga" do
      @assessments.save!(rated_on: "2026-11-01", entries: [ { competency_id: @communication.id, score: 2 } ])
      @assessments.save!(rated_on: "2026-11-01", entries: [ { competency_id: @communication.id, score: 5 } ])
      assert_equal [ 5 ], @communication.ratings.reload.map(&:score)

      @assessments.save!(rated_on: "2026-11-01", entries: [ { competency_id: @communication.id, score: nil } ])
      assert_equal 0, @communication.ratings.reload.count
    end

    test "uma nota só não tem variação" do
      @assessments.save!(rated_on: "2026-11-01", entries: [ { competency_id: @communication.id, score: 3 } ])
      assert_nil @assessments.competencies.first[:delta]
    end

    test "recusa competência de outra mentoria, nota fora de 1 a 5 e data inválida, sem gravar nada" do
      foreign = Mentorship.create!(mentor_name: "Bia").competencies.create!(name: "X")
      assert_raises(Assessments::Invalid) do
        @assessments.save!(rated_on: "2026-11-01", entries: [ { competency_id: @communication.id, score: 3 },
                                                              { competency_id: foreign.id, score: 3 } ])
      end
      assert_raises(Assessments::Invalid) do
        @assessments.save!(rated_on: "2026-11-01", entries: [ { competency_id: @communication.id, score: 6 } ])
      end
      assert_raises(Assessments::Invalid) { @assessments.save!(rated_on: "ontem", entries: []) }
      assert_equal 0, Rating.count
    end

    test "apaga a autoavaliação de uma data" do
      @assessments.save!(rated_on: "2026-11-01", entries: [ { competency_id: @communication.id, score: 3 } ])
      @assessments.save!(rated_on: "2026-11-02", entries: [ { competency_id: @communication.id, score: 4 } ])
      @assessments.destroy_date!("2026-11-01")
      assert_equal [ Date.new(2026, 11, 2) ], @assessments.dates
    end
  end
end
