# Busca reutilizável por qualquer módulo cuja tabela tenha a coluna
# "searchable" (tsvector). Combina:
#   - full-text: palavras inteiras, com ranking (título/tags pesam mais)
#   - ILIKE: pedaços de texto, úteis para nomes de funções e variáveis
#
#   class Nota < ApplicationRecord
#     include Searchable
#     searchable_partial_columns :titulo, :corpo
#   end
#   Nota.search("termo")
module Searchable
  extend ActiveSupport::Concern

  class_methods do
    def searchable_partial_columns(*columns)
      @searchable_partial_columns = columns
    end

    def partial_columns
      @searchable_partial_columns || []
    end

    def search(term)
      term = term.to_s.strip
      return all if term.blank?

      tsquery = sanitize_sql_array(["websearch_to_tsquery('simple', ?)", term])
      like = "%#{sanitize_sql_like(term)}%"

      conditions = ["#{table_name}.searchable @@ #{tsquery}"]
      conditions += partial_columns.map { |col| sanitize_sql_array(["#{table_name}.#{col} ILIKE ?", like]) }

      where(conditions.join(" OR "))
        .reorder(Arel.sql("ts_rank(#{table_name}.searchable, #{tsquery}) DESC, #{table_name}.updated_at DESC"))
    end
  end
end
