# Acervo

Organizador pessoal dividido em módulos. Backend em **Rails 8 (API)** com **PostgreSQL**, frontend em **React + TypeScript (Vite)**.

Primeiro módulo: **Códigos**, para guardar trechos de código e informações de projetos, com busca por termos.

```
acervo/
├── api/                  # Rails API
├── web/                  # React + TypeScript
└── docker-compose.yml    # PostgreSQL
```

## Como rodar

Requisitos: Ruby 3.2+, Node 20+ e PostgreSQL 14+ (ou Docker).

```bash
# 1. Banco (pule se já tiver PostgreSQL rodando, usuário/senha postgres)
docker compose up -d

# 2. Backend: http://localhost:3000
cd api
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server

# 3. Frontend: http://localhost:5173  (em outro terminal)
cd web
npm install
npm run dev
```

O Vite encaminha `/api` para o Rails, então não precisa configurar nada em desenvolvimento.
Usuário, senha e host do banco podem ser trocados por variáveis `DB_USER`, `DB_PASSWORD`, `DB_HOST`.

## Módulo Códigos

- **Códigos (snippets):** título, linguagem, tags, descrição, o código em si e, opcionalmente, um projeto.
- **Projetos:** nome, URL do repositório, tags e descrição/anotações livres.

### Busca

Uma busca procura em título, tags, linguagem, descrição e conteúdo do código, de duas formas ao mesmo tempo:

- **Palavras inteiras** (full-text do PostgreSQL), ordenadas por relevância: título e tags pesam mais que o corpo do código.
- **Pedaços de texto** (`ILIKE` com índice de trigramas): `useDeb` encontra `useDebounce`.

Também aceita a sintaxe de busca web: `"frase exata"`, `react -vue` (exclui), `rails or django`.

### Endpoints

| Método | Rota | Uso |
|---|---|---|
| GET | `/api/v1/modules` | Módulos habilitados |
| GET | `/api/v1/codes/snippets?q=&language=&tag=&project_id=&page=` | Lista/busca códigos |
| POST/PATCH/DELETE | `/api/v1/codes/snippets/:id` | CRUD de códigos |
| GET | `/api/v1/codes/projects?q=` | Lista/busca projetos |
| GET | `/api/v1/codes/projects/:id` | Projeto com seus códigos |
| POST/PATCH/DELETE | `/api/v1/codes/projects/:id` | CRUD de projetos |
| GET | `/api/v1/codes/search?q=` | Busca em projetos e códigos de uma vez |

Tags podem ser enviadas como array (`["react","hooks"]`) ou texto (`"react, hooks"`).

## Como adicionar um módulo novo

Exemplo: módulo `finance` (Finanças).

**Backend (`api/`)**
1. Registre em `config/modules.yml`.
2. Crie `app/models/finance.rb` com `table_name_prefix` `"finance_"` (copie `app/models/codes.rb`).
3. Models em `app/models/finance/` e uma migration com tabelas `finance_*`.
   Para busca, crie uma coluna `searchable` (tsvector) e use `include Searchable`.
4. Controllers em `app/controllers/api/v1/finance/` e rotas em `namespace :finance` no `config/routes.rb`.

**Frontend (`web/src/`)**
1. Crie `modules/finance/` com `api.ts`, `types.ts`, `pages/` e um `index.tsx` exportando um `OrganizerModule`.
2. Adicione-o à lista em `modules/index.ts`. O menu lateral e as rotas aparecem sozinhos.

Código compartilhado fica em `api/app/models/concerns/` (busca, tags) e `web/src/core/` (cliente HTTP, hooks, layout).

## Desenvolvimento assistido (Claude Code + Spec Kit)

O projeto usa o [Spec Kit](https://github.com/github/spec-kit) para desenvolvimento guiado por especificações.

- `CLAUDE.md`: comandos e convenções que o Claude Code segue.
- `.specify/memory/constitution.md`: princípios do projeto (modularidade, busca, qualidade…).
- `.claude/skills/`: comandos do Spec Kit.

Fluxo para uma feature nova, dentro do Claude Code:

```
/speckit-specify Módulo de finanças com lançamentos e categorias
/speckit-plan
/speckit-tasks
/speckit-implement
```

Opcionais: `/speckit-clarify` (antes do plano) e `/speckit-analyze` (antes de implementar).
