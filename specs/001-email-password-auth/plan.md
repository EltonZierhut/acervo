# Plano de implementação: Autenticação com e-mail e senha

**Branch**: `001-email-password-auth` | **Data**: 2026-10-30 | **Spec**: [spec.md](spec.md)

**Entrada**: especificação da feature em `specs/001-email-password-auth/spec.md`

## Resumo

Proteger todo o Acervo com login por e-mail e senha para um único usuário, criado e
administrado por comandos de terminal. A abordagem segue o gerador de autenticação do Rails 8
(`User`, `Session`, `Current`, concern `Authentication`, `has_secure_password`), adaptado ao
modo API: a sessão fica numa tabela no banco e é identificada por um token aleatório num
cookie assinado `HttpOnly`/`SameSite=Lax`, com expiração por 30 dias de inatividade e limite de
10 tentativas de login em 3 minutos. No React, um `AuthProvider` no núcleo protege todas as
rotas, mostra a tela de login e trata sessões expiradas. Os módulos não mudam. Detalhes e
alternativas em [research.md](research.md).

## Contexto técnico

**Linguagem/versão**: Ruby 3.2+ / Rails 8.0 (API); TypeScript 5 / React 19

**Dependências principais**: `bcrypt` (nova, exigida por `has_secure_password`); recursos
nativos do Rails 8 (`rate_limit`, `has_secure_token`, `authenticate_by`,
`CurrentAttributes`); React Router 7 (já existente)

**Armazenamento**: PostgreSQL (tabelas `users` e `sessions`); cache em memória para o limite
de tentativas

**Testes**: Minitest (`ActionDispatch::IntegrationTest`, fixtures). A infraestrutura de testes
é criada nesta feature. Frontend: `npm run build` (tipos) e `npm run lint`

**Plataforma**: servidor Linux; navegadores modernos

**Tipo de projeto**: aplicação web (API Rails + SPA React)

**Metas de desempenho**: login em menos de 1 s no servidor (custo do bcrypt padrão); sem
escrita no banco a cada requisição (atualização de atividade no máximo 1 vez por hora)

**Restrições**: credencial inacessível ao JavaScript; nenhuma senha em logs (o Rails já filtra
`password` por padrão; conferir `filter_parameters`); uma instância com um processo enquanto o
cache for em memória

**Escala/escopo**: 1 usuário; poucas sessões simultâneas; 3 endpoints novos e 2 comandos

## Verificação da constituição

*GATE: deve passar antes da Fase 0 e ser reavaliado depois da Fase 1.*

| Princípio | Avaliação | Status |
|---|---|---|
| I. Modularidade | Autenticação é núcleo: `app/models/{user,session,current}.rb`, `app/controllers/concerns/authentication.rb`, `Api::V1::SessionsController` fora de namespaces de módulo, `web/src/core/auth*`. Módulos não importam nada novo e continuam sem conhecer autenticação. | ✅ |
| II. Simplicidade | Usa o gerador oficial em vez de Devise, Rodauth ou JWT; cache em memória em vez de Redis. Única dependência nova: `bcrypt`, obrigatória para `has_secure_password` (ver Complexidade). | ✅ justificado |
| III. Busca | Não se aplica: usuários e sessões não são conteúdo pesquisável de um módulo. | ✅ n/a |
| IV. Contrato de API | Novas rotas em `/api/v1/session`; formatos de erro seguem `{ error }` (401, 415, 429). Rotas existentes mantêm o contrato, mas passam a exigir login: mudança coordenada com o frontend na mesma feature. | ✅ |
| V. Qualidade | Cria a base de Minitest; request tests da sessão, do limite de tentativas, da expiração e das tarefas Rake; teste que percorre todas as rotas de dados (SC-001). Migrations reversíveis. | ✅ |
| VI. Idioma | Mensagens, interface e comandos em pt-BR; código em inglês. | ✅ |

**Resultado (antes da pesquisa)**: aprovado. **Reavaliação após o design**: aprovado; o design
(data-model e contratos) não introduziu dependências, camadas ou acoplamentos além dos listados.

## Estrutura do projeto

### Documentação (desta feature)

```text
specs/001-email-password-auth/
├── spec.md
├── plan.md               # este arquivo
├── research.md           # Fase 0
├── data-model.md         # Fase 1
├── quickstart.md         # Fase 1
├── contracts/
│   ├── session-api.md    # endpoints e regras de autenticação
│   └── cli.md            # comandos de terminal
├── checklists/
│   └── requirements.md
└── tasks.md              # Fase 2 (/speckit-tasks)
```

### Código-fonte (arquivos novos ou alterados)

```text
api/
├── Gemfile                                     # + bcrypt
├── config/
│   ├── application.rb                          # + middleware ActionDispatch::Cookies
│   ├── environments/{development,test,production}.rb  # cache_store :memory_store
│   ├── initializers/filter_parameter_logging.rb       # filtra password, token
│   ├── locales/pt-BR.yml                       # + atributos/mensagens de user
│   └── routes.rb                               # + resource :session
├── app/
│   ├── models/
│   │   ├── user.rb                             # has_secure_password, normalização, validações
│   │   ├── session.rb                          # has_secure_token, expired?, touch_activity!
│   │   └── current.rb
│   └── controllers/
│       ├── application_controller.rb          # include Authentication, ActionController::Cookies, exige JSON
│       ├── concerns/authentication.rb         # require_authentication, allow_unauthenticated_access, cookie
│       └── api/v1/sessions_controller.rb      # create (rate_limit) / show / destroy
├── db/migrate/
│   ├── 2026103xxxxxxx_create_users.rb
│   └── 2026103xxxxxxx_create_sessions.rb
├── lib/tasks/acervo_user.rake                 # acervo:user:create / reset_password
└── test/
    ├── test_helper.rb                         # sign_in_as, reset do cache de rate limit
    ├── fixtures/{users,sessions}.yml
    ├── models/{user,session}_test.rb
    ├── controllers/api/v1/sessions_controller_test.rb
    ├── integration/authentication_required_test.rb   # todas as rotas /api/v1 → 401
    ├── integration/codes_api_test.rb          # fluxos atuais de Códigos, autenticados (SC-007)
    └── tasks/acervo_user_task_test.rb

web/src/
├── App.tsx                                    # rota /login pública; AuthProvider + RequireAuth no layout
└── core/
    ├── api.ts                                 # trata 401 (onUnauthorized) e 429
    ├── auth.tsx                               # AuthProvider, useAuth, RequireAuth
    ├── LoginPage.tsx                          # tela de login
    └── Layout.tsx                             # e-mail conectado + Sair
README.md                                      # criar conta, redefinir senha
CLAUDE.md                                      # convenções de autenticação para novos módulos
```

**Decisão de estrutura**: aplicação web com `api/` e `web/`, já existente. Autenticação mora no
núcleo dos dois lados; nenhum arquivo de `modules/codes` muda além dos testes novos.

## Notas de implementação

- **Ordem sugerida**: dependência e migrations → models → concern e `SessionsController` →
  exigir login em tudo → tarefas Rake → testes → frontend → documentação.
- **Novos módulos**: herdam a proteção automaticamente, porque o `ApplicationController` exige
  login por padrão. Uma rota só fica pública com `allow_unauthenticated_access`. Registrar isso
  no `CLAUDE.md`.
- **Exigir JSON (415)**: só para métodos que alteram dados; `GET`/`HEAD` passam.
- **Limite de tentativas nos testes**: limpar o cache entre os testes (`Rails.cache.clear` no
  `setup`) para não haver interferência.
- **Segredo dos cookies**: em desenvolvimento o Rails gera `tmp/local_secret.txt`; em produção é
  obrigatório `SECRET_KEY_BASE`. Registrar para a feature de deploy.
- **Ambiente sem RubyGems**: se a implementação acontecer num ambiente sem `bundle install`,
  validar a sintaxe com `ruby -c` e o SQL no PostgreSQL, e deixar claro que `bin/rails test`
  precisa rodar localmente antes do merge.

## Acompanhamento de complexidade

| Item | Por que é necessário | Alternativa mais simples rejeitada porque |
|---|---|---|
| Gem `bcrypt` | `has_secure_password` depende dela para guardar senhas de forma irreversível (FR-005) | Hash próprio com SHA ou PBKDF2 manual: inseguro ou reinventaria o que a gem padrão do Rails já faz |
| Tabela `sessions` | Permite invalidar sessões no logout e na redefinição de senha (FR-008, FR-016) | Cookie de sessão sem estado: não dá para revogar no servidor |
