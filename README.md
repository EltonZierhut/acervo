# Acervo

Organizador pessoal dividido em módulos. Backend em **Rails 8 (API)** com **PostgreSQL**, frontend em **React + TypeScript (Vite)**.

Módulos:

- **Códigos**: bloco de notas para colar scripts e trechos de código e encontrá-los rápido.
- **Iniciativas**: projetos de qualquer tipo (trabalho, jogo, reforma…) com marcos e tarefas.

```
acervo/
├── api/                  # Rails API
├── web/                  # React + TypeScript
└── docker-compose.yml    # PostgreSQL, Rails e Vite para desenvolvimento
```

## Como rodar

### Com Docker

Requisito: só o Docker. O código fica montado no container, então as alterações valem na hora.

```bash
docker compose up -d                                  # sobe tudo: http://localhost:5173
docker compose logs -f dev                            # acompanha a instalação e os servidores
docker compose exec dev bin/rails acervo:user:create  # cria a sua conta (só na primeira vez)
docker compose exec dev bin/rails test                # roda os testes
docker compose down                                   # para tudo (os dados continuam no volume)
```

A primeira subida demora alguns minutos, porque instala as dependências. As portas 3000 e 5173 precisam
estar livres; para usar outras: `API_PORT=3001 WEB_PORT=5174 docker compose up -d`.

### Na máquina

Requisitos: Ruby 3.2+, Node 20+ e PostgreSQL 14+ (ou Docker).

```bash
# 1. Banco (pule se já tiver PostgreSQL rodando, usuário/senha postgres)
docker compose up -d db

# 2. Backend: http://localhost:3000
cd api
bundle install
bin/rails db:create db:migrate db:seed
bin/rails acervo:user:create      # cria a sua conta (pede e-mail e senha)
bin/rails server

# 3. Frontend: http://localhost:5173  (em outro terminal)
cd web
npm install
npm run dev
```

O Vite encaminha `/api` para o Rails, então não precisa configurar nada em desenvolvimento.
Usuário, senha e host do banco podem ser trocados por variáveis `DB_USER`, `DB_PASSWORD`, `DB_HOST`.

Testes do backend: `cd api && bin/rails test`.

## Acesso (login)

Todo o Acervo exige login com e-mail e senha. Não há tela de cadastro: a conta é administrada pelo terminal, dentro de `api/`.

```bash
bin/rails acervo:user:create           # cria a conta (nesta versão, só uma)
bin/rails acervo:user:reset_password   # define uma nova senha e encerra as sessões abertas
```

A senha é digitada sem aparecer na tela e precisa ter pelo menos 12 caracteres.

- A sessão fica num cookie `HttpOnly` e vale até você sair ou ficar 30 dias sem usar.
- Depois de 10 tentativas de login em 3 minutos, as próximas são recusadas por alguns minutos.
- **Produção:** defina a variável `SECRET_KEY_BASE` (gere com `bin/rails secret`). Ela assina o cookie de sessão.

## Publicação

O Acervo é publicado como um único serviço no **Google Cloud Run** (São Paulo), com banco no
**Cloud SQL**, que tem custo mensal fixo. O `Dockerfile` da raiz compila o React e monta a imagem do Rails, que entrega a interface
e a API no mesmo endereço.

Depois de configurado, cada merge na `main` é publicado pelo GitHub Actions, se os testes passarem.

```bash
bin/setup-gcp      # configura Google Cloud e GitHub (uma vez)
bin/deploy-gcp     # publica da sua máquina, sem o GitHub Actions
bin/prod-rails acervo:user:create   # roda uma tarefa do Rails no banco de produção
```

Passo a passo completo, incluindo contas, segredos e custos: [docs/deploy-gcp.md](docs/deploy-gcp.md).

Para testar a imagem localmente:

```bash
docker build -t acervo .
docker run --rm -p 8080:8080 -e DATABASE_URL=... -e SECRET_KEY_BASE=... acervo
```

## Módulo Códigos

- **Notas (snippets):** basta colar o conteúdo, e a nota é salva automaticamente. Título, tags, linguagem e descrição são opcionais; sem título, a lista mostra a primeira linha.
- O conteúdo fica em texto legível no banco e na tela: não guarde senhas nem chaves nas notas.

### Busca

Uma busca procura em título, tags, linguagem, descrição e conteúdo da nota, de duas formas ao mesmo tempo:

- **Palavras inteiras** (full-text do PostgreSQL), ordenadas por relevância: título e tags pesam mais que o corpo do código.
- **Pedaços de texto** (`ILIKE`) em título, tags, descrição e conteúdo: `useDeb` encontra `useDebounce`.

Também aceita a sintaxe de busca web: `"frase exata"`, `react -vue` (exclui), `rails or django`.

### Endpoints

Todas exigem login, exceto `POST /api/v1/session` e `GET /up`. Requisições que alteram dados precisam de `Content-Type: application/json`.

| Método | Rota | Uso |
|---|---|---|
| POST | `/api/v1/session` | Entrar (`email_address`, `password`) |
| GET | `/api/v1/session` | Usuário logado |
| DELETE | `/api/v1/session` | Sair |
| GET | `/api/v1/modules` | Módulos habilitados |
| GET | `/api/v1/codes/snippets?q=&language=&tag=&page=` | Lista/busca notas (sem o conteúdo) |
| GET | `/api/v1/codes/snippets/:id` | Nota completa |
| POST/PATCH/DELETE | `/api/v1/codes/snippets/:id` | Cria, altera e apaga notas |

Tags podem ser enviadas como array (`["react","hooks"]`) ou texto (`"react, hooks"`).

## Módulo Iniciativas

Organiza qualquer coisa com objetivo e etapas: um projeto do trabalho, o desenvolvimento de um jogo,
uma reforma. Fica em `/iniciativas`.

- **Contextos**: áreas que você mesmo cria ("Trabalho", "Casa", "Jogo"), com cor, para filtrar a lista.
- **Iniciativa**: nome (único campo obrigatório), descrição, status (ideia, planejada, ativa,
  pausada, encerrada), prioridade, datas, tags e as **seções** que ela usa. Encerradas saem da
  lista padrão, mas continuam no filtro.
- **Tarefas**: criadas só com o título (Enter adiciona e já deixa o campo pronto para a próxima);
  status, prioridade, prazo e marco são opcionais. Atrasadas aparecem destacadas.
- **Marcos**: grandes entregas, com data-alvo e progresso das tarefas ligadas a eles.

Busca por palavra e por pedaço em nome, descrição e tags das iniciativas, e em título e descrição
das tarefas. Decisões, notas, ideias, documentos e riscos entram nas próximas fases
(`specs/005-initiatives-module/spec.md`). Endpoints em
[`specs/005-initiatives-module/contracts/initiatives-api.md`](specs/005-initiatives-module/contracts/initiatives-api.md).

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
