require "test_helper"

module Flashcards
  # Regras de research.md, cenário por cenário (SC-002).
  class SchedulerTest < ActiveSupport::TestCase
    FakeCard = Struct.new(:state, :step_index, :interval_days, :ease, :lapses, keyword_init: true)

    setup do
      @now = Time.zone.local(2026, 11, 7, 10, 0)
      @scheduler = Scheduler.new(now: @now, fuzz: false)
    end

    def card(state: "new", step_index: 0, interval_days: 0, ease: 2500, lapses: 0)
      FakeCard.new(state:, step_index:, interval_days:, ease:, lapses:)
    end

    def day(n)
      Time.zone.local(2026, 11, 7, 4, 0).advance(days: n)
    end

    test "novo: Errei e Bom ficam nos passos de 1 e 10 min" do
      again = @scheduler.answer(card, 1)
      assert_equal [ "learning", 0, @now + 1.minute ], [ again.state, again.step_index, again.due_at ]

      good = @scheduler.answer(card, 3)
      assert_equal [ "learning", 1, @now + 10.minutes ], [ good.state, good.step_index, good.due_at ]
    end

    test "novo: Difícil usa a média dos dois primeiros passos" do
      hard = @scheduler.answer(card, 2)
      assert_equal "learning", hard.state
      assert_equal @now + 330.seconds, hard.due_at
    end

    test "novo: Fácil gradua em 4 dias com a facilidade inicial" do
      easy = @scheduler.answer(card, 4)
      assert_equal [ "review", 4, 2500, day(4) ], [ easy.state, easy.interval_days, easy.ease, easy.due_at ]
    end

    test "aprendizado: Bom no último passo gradua em 1 dia" do
      result = @scheduler.answer(card(state: "learning", step_index: 1), 3)
      assert_equal [ "review", 1, day(1) ], [ result.state, result.interval_days, result.due_at ]
    end

    test "aprendizado: Difícil no último passo repete o passo e Errei volta ao primeiro" do
      hard = @scheduler.answer(card(state: "learning", step_index: 1), 2)
      assert_equal [ 1, @now + 10.minutes ], [ hard.step_index, hard.due_at ]

      again = @scheduler.answer(card(state: "learning", step_index: 1), 1)
      assert_equal [ 0, @now + 1.minute ], [ again.step_index, again.due_at ]
    end

    test "revisão: intervalos de Difícil, Bom e Fácil e ajuste da facilidade" do
      review = card(state: "review", interval_days: 10, ease: 2500)

      hard = @scheduler.answer(review, 2)
      assert_equal [ 12, 2350 ], [ hard.interval_days, hard.ease ]

      good = @scheduler.answer(review, 3)
      assert_equal [ 25, 2500, day(25) ], [ good.interval_days, good.ease, good.due_at ]

      easy = @scheduler.answer(review, 4)
      assert_equal [ 33, 2650 ], [ easy.interval_days, easy.ease ] # 10 × 2,5 × 1,3 = 32,5
    end

    test "revisão: cada resposta melhor dá pelo menos um dia a mais" do
      review = card(state: "review", interval_days: 1, ease: 1300)
      intervals = (2..4).map { |rating| @scheduler.answer(review, rating).interval_days }
      assert_equal [ 2, 3, 4 ], intervals
    end

    test "revisão: Errei vai para reaprendizado, perde facilidade e conta lapso" do
      result = @scheduler.answer(card(state: "review", interval_days: 30, ease: 2500, lapses: 2), 1)
      assert_equal [ "relearning", 0, 1, 2300, 3 ], [ result.state, result.step_index, result.interval_days, result.ease, result.lapses ]
      assert_equal @now + 10.minutes, result.due_at
    end

    test "facilidade nunca fica abaixo de 1,3" do
      result = @scheduler.answer(card(state: "review", interval_days: 5, ease: 1350), 1)
      assert_equal 1300, result.ease
    end

    test "intervalo é limitado ao máximo" do
      result = @scheduler.answer(card(state: "review", interval_days: 30_000, ease: 2500), 3)
      assert_equal Scheduler::MAXIMUM_INTERVAL, result.interval_days
    end

    test "reaprendizado: Bom volta à revisão com o intervalo guardado e Fácil com um dia a mais" do
      relearning = card(state: "relearning", interval_days: 1, ease: 2300, lapses: 1)

      good = @scheduler.answer(relearning, 3)
      assert_equal [ "review", 1, day(1) ], [ good.state, good.interval_days, good.due_at ]

      easy = @scheduler.answer(relearning, 4)
      assert_equal [ "review", 2 ], [ easy.state, easy.interval_days ]

      again = @scheduler.answer(relearning, 1)
      assert_equal [ "relearning", @now + 10.minutes ], [ again.state, again.due_at ]
    end

    test "dia de estudo vira às 4h: de madrugada, 1 dia vence às 4h do mesmo dia civil" do
      late = Time.zone.local(2026, 11, 8, 1, 30)
      result = Scheduler.new(now: late, fuzz: false).answer(card(state: "learning", step_index: 1), 3)
      assert_equal Time.zone.local(2026, 11, 8, 4, 0), result.due_at
    end

    test "variação fica em ±5% e não mexe em intervalos curtos" do
      scheduler = Scheduler.new(now: @now, random: Random.new(42))
      review = card(state: "review", interval_days: 40, ease: 2500)
      intervals = Array.new(30) { scheduler.answer(review, 3).interval_days }
      assert intervals.all? { |days| (95..105).cover?(days) }, intervals.inspect
      assert_operator intervals.uniq.size, :>, 1

      assert_equal 1, scheduler.answer(card(state: "learning", step_index: 1), 3).interval_days
    end

    test "resposta fora de 1 a 4 é recusada" do
      assert_raises(ArgumentError) { @scheduler.answer(card, 5) }
    end

    test "textos dos intervalos" do
      results = @scheduler.preview(card)
      assert_equal [ "1 min", "6 min", "10 min", "4 dias" ], results.values.map { |r| Scheduler.label(r, @now) }

      label = ->(days) { Scheduler.label(Scheduler::Result.new(state: "review", step_index: 0, interval_days: days, ease: 2500, lapses: 0, due_at: nil)) }
      assert_equal "1 dia", label.call(1)
      assert_equal "1 mês", label.call(30)
      assert_equal "3,5 meses", label.call(105)
      assert_equal "1,2 ano", label.call(438)
      assert_equal "2 h", Scheduler.minutes_label(120)
    end
  end
end
