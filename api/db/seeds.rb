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

game = Initiatives::Context.find_or_create_by!(name: "Jogo") { |c| c.color = "#7c3aed" }
Initiatives::Context.find_or_create_by!(name: "Trabalho") { |c| c.color = "#2f6fed" }

unless Initiatives::Initiative.exists?(name: "Jogo para a Steam")
  initiative = Initiatives::Initiative.create!(
    name: "Jogo para a Steam", context: game, status: "active", priority: "high",
    description: "Exemplo: um jogo de PC, do protótipo à página na loja.", tags: %w[jogo]
  )
  prototype = initiative.milestones.create!(title: "Protótipo jogável", due_on: 2.months.from_now.to_date)
  initiative.milestones.create!(title: "Página na Steam")
  initiative.tasks.create!(title: "Escolher a engine", status: "done")
  initiative.tasks.create!(title: "Movimento do personagem", status: "doing", milestone: prototype)
  initiative.tasks.create!(title: "Primeira fase", milestone: prototype)
end

puts "Seeds criados: #{Codes::Snippet.count} nota(s) e #{Initiatives::Initiative.count} iniciativa(s)."
