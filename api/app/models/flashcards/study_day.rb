module Flashcards
  # O dia de estudo vira às 4h (no fuso da aplicação), como no Anki: quem estuda de madrugada
  # continua no dia anterior.
  module StudyDay
    ROLLOVER_HOUR = 4

    module_function

    def start(now = Time.current)
      now = now.in_time_zone
      day = now.hour < ROLLOVER_HOUR ? now.to_date - 1 : now.to_date
      day.in_time_zone.change(hour: ROLLOVER_HOUR)
    end

    def finish(now = Time.current)
      start(now).advance(days: 1)
    end

    # Início do dia de estudo daqui a `days` dias.
    def after(days, now = Time.current)
      start(now).advance(days: days)
    end
  end
end
