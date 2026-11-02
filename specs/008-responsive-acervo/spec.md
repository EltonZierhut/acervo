# Especificação: Premissa e Acervo responsivo

Como usuário, quero usar o Acervo no celular com o mesmo conforto do computador, para consultar e anotar coisas onde eu estiver.

## Premissa (vale para toda feature)

Toda tela funciona a partir de 360 px sem rolagem horizontal da página; toda interação é possível por toque.
Registrada como princípio VII (constituição 1.2.0), no `CLAUDE.md` e no template de checklist.

## Requisitos

- Barra inferior fixa no celular (ícone SVG e nome); conta e "Sair" num menu. Computador: barra lateral como antes.
- Alvos de toque de pelo menos 44 × 44 px; campos de pelo menos 16 px no celular.
- Modais em tela cheia com fechar sempre visível; telas de dois painéis mostram um por vez, com voltar.
- Áreas seguras (`viewport-fit=cover`).
- Todas as telas atuais revisadas: login, Códigos (lista, editor, busca na nota), Iniciativas (lista, página com abas, tarefas, marcos, contextos, formulários, fila) e o quadro de tarefas.
- CodeMirror no celular: seleção e cópia, teclado virtual sem cobrir a linha editada, busca na nota.

## Critérios de aceite

1. Em 360 px nenhuma tela tem rolagem horizontal; botões tocáveis sem zoom.
2. No celular a navegação fica na barra inferior e "Sair" está no menu da conta.
3. Focar um campo no iPhone não dá zoom.
4. Teste automatizado abre cada rota em 360 px e falha com rolagem horizontal.
5. Constituição, `CLAUDE.md` e template de checklist têm a premissa.

## Fora do escopo

App instalável, layout específico de tablet, gestos como deslizar para apagar.
