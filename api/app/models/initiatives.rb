# Namespace do módulo Iniciativas. Tabelas usam o prefixo "initiatives_".
module Initiatives
  def self.table_name_prefix
    "initiatives_"
  end

  PRIORITIES = { low: "low", medium: "medium", high: "high" }.freeze
end
