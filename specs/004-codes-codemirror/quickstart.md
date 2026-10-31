# Roteiro de validação: Editor de código nas notas

## Preparação

```bash
docker compose up -d
(cd api && bin/rails server)
(cd web && npm install && npm run dev)   # http://localhost:5173
```

## Verificações automáticas

```bash
cd web && npm run build && npm run lint
```

Os dois passam sem erros. No resultado do build, o editor e as linguagens aparecem em arquivos separados do `index-*.js`.

## Roteiro manual

| # | Ação | Resultado esperado | Requisito |
|---|------|--------------------|-----------|
| 1 | Abrir uma nota com várias linhas | Números de linha, linha atual destacada, fonte monoespaçada, cursor no conteúdo | FR-001 a FR-003 |
| 2 | Pressionar Tab; depois Esc e Tab | Primeiro indenta; depois o foco sai do editor | FR-001, FR-011 |
| 3 | Criar nota nova | Texto de orientação visível | FR-003 |
| 4 | Colar um script com tabulações, espaços no fim da linha e acentos; recarregar | Salvamento imediato; texto idêntico ao original | FR-005, FR-006, SC-001 |
| 5 | Digitar e parar | "Salvando" e "salvo" como hoje | FR-005 |
| 6 | Alterar e sair logo em seguida | A alteração é salva antes de sair | FR-005 |
| 7 | Derrubar a API, editar, religar e usar "Restaurar" | O rascunho aparece no editor | FR-007 |
| 8 | Clicar em "Copiar" em nota longa | A área de transferência tem o conteúdo integral | FR-007 |
| 9 | Abrir nota com CRLF (inserida pelo console do Rails) sem editar, olhando a aba Rede | Nenhum `PATCH` e nenhum aviso ao sair | FR-008 |
| 10 | Definir a linguagem como `sql`, depois `bash`, `typescript` e `xyz`; apagar | O realce acompanha, o cursor não se move, e `xyz` ou vazio dão texto simples | FR-009 |
| 11 | Ctrl+F no editor, em nota longa, por um trecho do fim | Painel em português encontra o trecho | FR-010 |
| 12 | Alternar o tema do sistema | Editor e realce acompanham, com contraste legível | FR-004 |
| 13 | Arrastar a borda inferior | A altura muda; nunca fica abaixo de 60% da tela | FR-012 |
| 14 | Colar uma linha muito longa | Rolagem horizontal, sem quebra | FR-002 |
| 15 | Nota com cerca de 1 MB: abrir, rolar e digitar | Abre em até 2 s, sem atraso perceptível | SC-003 |
| 16 | Abrir `/login` em aba anônima, olhando a aba Rede | Nenhum arquivo do editor é baixado | SC-004 |
| 17 | Bloquear o arquivo do editor na aba Rede e abrir uma nota | Mensagem de erro clara; a barra e "Mais detalhes" continuam na tela | Casos extremos |
