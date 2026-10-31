Codes::Snippet.find_or_create_by!(title: "Hook de debounce") do |s|
  s.language = "typescript"
  s.tags = %w[react hooks]
  s.description = "Atrasa a atualização de um valor, útil para campos de busca."
  s.content = <<~TS
    import { useEffect, useState } from "react";

    export function useDebounce<T>(value: T, delay = 300): T {
      const [debounced, setDebounced] = useState(value);
      useEffect(() => {
        const id = setTimeout(() => setDebounced(value), delay);
        return () => clearTimeout(id);
      }, [value, delay]);
      return debounced;
    }
  TS
end

Codes::Snippet.find_or_create_by!(title: "Backup do PostgreSQL") do |s|
  s.language = "bash"
  s.tags = %w[postgres backup]
  s.description = "Gera um dump compactado do banco."
  s.content = "pg_dump -Fc acervo_development > backup_$(date +%F).dump"
end

puts "Seeds criados: #{Codes::Snippet.count} nota(s)."
