# Spec 007: Quadro de tarefas estilo Jira no módulo Iniciativas

Substitui a lista de tarefas agrupada por status, com edição na própria linha, por um quadro com colunas,
cards arrastáveis e um modal de edição com descrição em texto rico.

## Requisitos

- **Quadro**: a aba Tarefas mostra Backlog, Executando e Finalizado (`todo`, `doing`, `done`; nenhum dado é
  perdido). Cada coluna mostra nome, quantidade e cards em ordem. Arrastar muda o status (entre colunas) ou a
  ordem (na mesma coluna), e a ordem fica salva. Entrar em Finalizado grava `completed_at`; sair apaga.
- **Criação**: "+ Criar" no rodapé de cada coluna; Enter cria o card naquela coluna.
- **Busca e filtros** (marco, prioridade) escondem cards sem mudar as colunas. A busca acha palavras da
  descrição formatada (o texto, não as marcações).
- **Card**: título (3 linhas), prioridade, marco, prazo (vermelho se atrasado), ícone de descrição e número
  `#12` (numeração por iniciativa). Clicar abre o modal.
- **Modal**: endereço próprio (`/iniciativas/1?aba=tarefas&tarefa=12`); o botão voltar fecha. Título editável,
  descrição em texto rico (negrito, itálico, listas, checklists, links, títulos, citação, bloco de código),
  coluna lateral com status, prioridade, prazo, marco e datas. Salvamento automático com "Salvando…"/"Salvo";
  fechar com alteração pendente tenta salvar e avisa se não conseguir. Apagar com confirmação. Fecha com Esc,
  X ou clique fora; atalhos do editor não fecham.
- **Colagem**: mantém formatação básica e descarta fontes, cores e estilos. Imagens são ignoradas, sem erro.
- **Fora do escopo**: imagens e anexos na descrição, subtarefas, comentários, histórico, colunas
  personalizadas, responsáveis e estimativas. (Os anexos e links e a execução por IA da spec 006 continuam
  disponíveis, agora dentro do modal.)

## Critérios de aceite

1. Arrastar de Backlog para Executando muda o status e mantém a posição depois de recarregar.
2. Colar de uma página web mantém negrito, listas e links, sem fontes e cores.
3. Colar uma imagem não insere nada nem quebra o editor.
4. Abrir `/iniciativas/1?tarefa=12` direto abre o quadro com o modal.
5. A busca encontra palavras da descrição formatada.
6. Tarefas existentes caem nas colunas certas e as descrições em texto puro continuam legíveis.
