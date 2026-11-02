# Plano: Acervo responsivo

## Decisões

- **Ponto de quebra**: continua um só, 720 px. `@media` não aceita `var()`, então padronizar em variável CSS não funciona;
  o valor fica documentado no CSS e em `core/breakpoints.ts`. Variáveis CSS são usadas para o que muda dentro dele (`--touch`, `--bottom-bar`).
- **CSS**: `index.css` continua único (≈400 linhas); as regras de celular ficam num só bloco, o que facilita revisar a premissa. Dividir por módulo fica para quando o arquivo pesar.
- **Navegação**: `Layout.tsx` renderiza a barra lateral e a barra inferior; o CSS mostra uma por vez. `OrganizerModule.icon` passou de `string` para `ReactNode`, com SVGs embutidos em `core/icons.tsx` (sem biblioteca).
- **Viewport**: `viewport-fit=cover` (áreas seguras) e `interactive-widget=resizes-content` (o teclado virtual encolhe a janela no Android). No iOS, `CodeEditor` rola o cursor para a vista quando `visualViewport` muda.
- **Quadro de tarefas**: no celular as colunas empilham (sem rolagem lateral); o arrasto é por toque longo e o status também muda no modal da tarefa (alternativa sem arrastar).
- **Teste**: `@playwright/test` como dependência de desenvolvimento (Constituição II: justificada). É a forma de medir `scrollWidth`, tamanho dos alvos e fontes em navegador real, nos temas claro e escuro. Roda contra a **API simulada** (`page.route`), então só precisa do Vite: rápido e sem banco. Como a API não é exercitada, os fixtures em `e2e/mock-api.ts` seguem `types.ts`.

## Constitution Check

I–VI sem conflito. VII: é o próprio princípio introduzido aqui. II: dependência nova justificada acima.

## Pendência

O CI (`.github/workflows/ci.yml`) ainda não roda `npm run test:e2e`; precisa de `npx playwright install --with-deps chromium`.
