# Spec 008: Acervo instalável (PWA)

**Depende de**: telas adaptadas ao celular. **Princípio**: VII (Responsivo e instalável).

## História
Como usuário, quero abrir o Acervo pela tela inicial do celular como um app, para chegar rápido no que preciso.

## Requisitos
- Manifesto "Acervo": ícones (192, 512, adaptável do Android, iPhone), cor do tema claro/escuro, `standalone`, início em `/`.
- Instalação: Android e Chrome desktop oferecem "Instalar"; no iPhone, dica dispensável "Compartilhar → Adicionar à Tela de Início".
- Service worker guarda a interface (HTML, JS, CSS, ícones); abre rápido e sem internet.
- Offline: o app abre e avisa; dados não ficam no aparelho. Salvamento sem rede segue a regra existente ("Não salvo", nova tentativa, aviso ao sair).
- Atualização: aviso "Nova versão disponível — Atualizar"; nunca aplicada sozinha.
- Login: cookie HttpOnly; nada de credenciais nem de `/api` no cache.
- Atalhos: "Nova nota" (`/codigos/novo`) e "Nova tarefa" (`/iniciativas?nova_tarefa=1`, pede a iniciativa).

## Fora do escopo
Dados offline com sincronização, push, Share Target, app nativo nas lojas.

## Decisões técnicas
- **Service worker escrito à mão** (sem `vite-plugin-pwa`/Workbox): evita dependência nova. O versionamento do cache
  é resolvido por um plugin de ~15 linhas no `vite.config.ts` que gera o `sw.js` com a lista de arquivos do build; a
  lista (com hashes) muda a cada versão, então o `sw.js` e o nome do cache mudam junto.
- **Onde servir**: `sw.js`, manifesto e ícones vão para `api/frontend/` no Dockerfile e são entregues por `PwaController`
  em rotas explícitas anteriores ao catch-all (`no-cache` para sw.js e manifesto; 1 dia para ícones).
- **Escopo do cache**: só `/`, `/assets/*`, `/icons/*`, `/favicon.svg`, manifesto. `/api` e `/up` passam direto pela rede.
- **Ícones**: gerados com ImageMagick a partir de `web/icon-src/*.svg` (comando no quickstart).
