---
description: "Lista de tarefas da feature 001: autenticação com e-mail e senha"
---

# Tarefas: Autenticação com e-mail e senha

**Entrada**: documentos de design em `specs/001-email-password-auth/`

**Pré-requisitos**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Testes**: incluídos. A spec exige testes automatizados de todas as rotas (SC-001), e a
constituição (princípio V) exige request tests e testes de models com regras próprias.

**Organização**: tarefas agrupadas por história de usuário. Caminhos relativos à raiz do
repositório (`api/` = Rails, `web/` = React).

## Formato: `[ID] [P?] [História] Descrição`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa pendente)
- **[USn]**: história de usuário da spec.md

---

## Fase 1: Setup (infraestrutura compartilhada)

**Propósito**: dependência, configuração e base de testes

- [X] T001 Adicionar `gem "bcrypt", "~> 3.1.7"` em `api/Gemfile` (único gem novo; justificado no plan.md)
- [X] T002 [P] Definir `config.cache_store = :memory_store` em `api/config/environments/development.rb` (substituindo `:null_store`), `api/config/environments/test.rb` e `api/config/environments/production.rb`
- [X] T003 [P] Adicionar `config.middleware.use ActionDispatch::Cookies` em `api/config/application.rb` (modo API não carrega cookies) e garantir `config.filter_parameters += %i[passw email_address token secret _key crypt salt certificate otp ssn]` em `api/config/initializers/filter_parameter_logging.rb`
- [X] T004 [P] Criar a base de testes Minitest: `api/test/test_helper.rb` (fixtures, `parallelize` desligado, `setup { Rails.cache.clear }`), `api/test/fixtures/.keep` e o helper `sign_in_as(user, password: "senha-de-teste-123")` que faz `POST /api/v1/session` em JSON

---

## Fase 2: Fundação (pré-requisitos bloqueantes)

**Propósito**: models, schema e o mecanismo de autenticação usados por todas as histórias

**⚠️ CRÍTICO**: nenhuma história começa antes desta fase terminar

- [X] T005 Criar migration `api/db/migrate/20261030000002_create_users.rb`: `users` com `email_address` string `null: false` (índice único) e `password_digest` string `null: false`, mais timestamps; reversível
- [X] T006 Criar migration `api/db/migrate/20261030000003_create_sessions.rb`: `sessions` com `user_id` (`references`, `null: false`, `foreign_key: { on_delete: :cascade }`), `token` string `null: false` (índice único), `ip_address` string, `user_agent` string, `last_active_at` datetime `null: false`, mais timestamps; reversível
- [X] T007 [P] Criar `api/app/models/user.rb`: `has_secure_password`, `has_many :sessions, dependent: :destroy`, `normalizes :email_address, with: ->(e) { e.strip.downcase }`, validações "e-mail obrigatório, único (case-insensitive), formato válido (`URI::MailTo::EMAIL_REGEXP`)" e "senha: mínimo de 12 caracteres (FR-017); máximo de 72 bytes" (`allow_nil: true` para updates sem senha), e o método `reset_password!(password, password_confirmation)` que atualiza a senha e apaga todas as `sessions` numa transação, retornando o número de sessões encerradas
- [X] T008 [P] Criar `api/app/models/session.rb`: `belongs_to :user`, `has_secure_token :token`, constantes `IDLE_TIMEOUT = 30.days` e `ACTIVITY_INTERVAL = 1.hour`, `before_validation` que preenche `last_active_at` na criação, `expired?` (`last_active_at < IDLE_TIMEOUT.ago`) e `touch_activity!` (atualiza `last_active_at` só se passou de `ACTIVITY_INTERVAL`; retorna true se atualizou)
- [X] T009 [P] Criar `api/app/models/current.rb`: `ActiveSupport::CurrentAttributes` com `attribute :session` e `delegate :user, to: :session, allow_nil: true`
- [X] T010 Criar `api/app/controllers/concerns/authentication.rb`: `before_action :require_authentication` por padrão; `class_method allow_unauthenticated_access(**options)` (usa `skip_before_action`); `resume_session` lê `cookies.signed[:session_token]`, busca a `Session` pelo token, apaga e ignora se `expired?`, chama `touch_activity!` e renova o cookie quando atualizou; `request_authentication` responde `401 { error: "Não autenticado" }`; `start_new_session_for(user)` cria a sessão com `ip_address`/`user_agent` e grava o cookie (`httponly: true, same_site: :lax, secure: Rails.env.production?, expires: Session::IDLE_TIMEOUT.from_now`); `terminate_session` apaga a sessão e o cookie
- [X] T011 Alterar `api/app/controllers/application_controller.rb`: `include ActionController::Cookies` e `include Authentication`; `before_action :require_json_body` (antes da autenticação) que responde `415 { error: "Use JSON (Content-Type: application/json)" }` para `POST/PUT/PATCH/DELETE` sem `request.media_type == "application/json"`
- [X] T012 [P] Adicionar ao `api/config/locales/pt-BR.yml` o model `user` (Usuário) e atributos `email_address` (E-mail), `password` (Senha) e `password_confirmation` (Confirmação da senha), além das mensagens `too_short` e `confirmation` usadas pelas validações
- [X] T013 [P] Criar fixtures `api/test/fixtures/users.yml` (um usuário `owner` com `password_digest: <%= BCrypt::Password.create("senha-de-teste-123") %>`) e `api/test/fixtures/sessions.yml` (vazio ou uma sessão de exemplo)
- [X] T014 [P] Criar testes de model `api/test/models/user_test.rb` (normalização do e-mail, unicidade case-insensitive, senha com menos de 12 caracteres recusada, `reset_password!` apaga sessões) e `api/test/models/session_test.rb` (token gerado, `expired?` após 30 dias, `touch_activity!` respeita o intervalo de 1 hora)

**Checkpoint**: models e concern prontos; `bin/rails test test/models` verde

---

## Fase 3: História 1 – Entrar com e-mail e senha e proteger o Acervo (P1) 🎯 MVP

**Objetivo**: nada acessível sem login; login por e-mail e senha cria sessão por cookie

**Teste independente**: sem login, API → 401 e telas → login; com credenciais certas, o conteúdo aparece

### Testes da História 1

- [X] T015 [P] [US1] Criar `api/test/controllers/api/v1/sessions_controller_test.rb` com: login válido → 201, corpo `{ user: { id, email_address } }` e cookie `session_token` HttpOnly/SameSite=Lax; e-mail com maiúsculas e espaços aceito; senha errada e e-mail inexistente → 401 com a mesma mensagem "E-mail ou senha inválidos"; `GET /api/v1/session` → 200 logado e 401 sem login; sessão expirada (`last_active_at` 31 dias atrás) → 401 e registro apagado; POST sem JSON → 415
- [X] T016 [P] [US1] Criar `api/test/integration/authentication_required_test.rb` que percorre `Rails.application.routes.routes`, seleciona rotas com caminho começando em `/api/v1` exceto `POST /api/v1/session`, substitui segmentos dinâmicos (`:id` → `1`) e verifica que cada uma responde 401 sem login (SC-001); e que `GET /up` responde 200
- [X] T017 [P] [US1] Criar `api/test/integration/codes_api_test.rb` cobrindo, já logado, os fluxos atuais do módulo Códigos (SC-007): criar, listar, buscar (`q=`), mostrar, atualizar e apagar snippet; criar projeto e listar com `snippets_count`; `GET /api/v1/codes/search`

### Implementação da História 1

- [X] T018 [US1] Criar `api/app/controllers/api/v1/sessions_controller.rb`: `allow_unauthenticated_access only: :create`; `create` usa `User.authenticate_by(email_address: params.require(:email_address), password: params.require(:password))`, chama `start_new_session_for` e responde 201 com `{ user: { id, email_address } }`, ou 401 `{ error: "E-mail ou senha inválidos" }`; `show` responde 200 com o usuário atual (`Current.user`)
- [X] T019 [US1] Adicionar `resource :session, only: %i[create show destroy]` dentro de `namespace :api / :v1` em `api/config/routes.rb` (antes dos módulos)
- [X] T020 [P] [US1] Alterar `web/src/core/api.ts`: função `setUnauthorizedHandler(fn)`; em respostas 401 de qualquer rota exceto `/session`, chamar o handler antes de lançar `ApiError`; exportar `authApi` com `login(email_address, password)`, `current()` e `logout()` usando `/session`
- [X] T021 [US1] Criar `web/src/core/auth.tsx`: `AuthProvider` (estado `user | null`, `status: 'loading' | 'authenticated' | 'anonymous'`, consulta `authApi.current()` ao montar, registra o handler de 401 que zera o usuário e navega para `/login?next=<rota atual>&expired=1`), hook `useAuth()` com `user`, `login`, `logout`, e componente `RequireAuth` que mostra "Carregando…" durante `loading` e redireciona anônimos para `/login?next=<rota atual>`
- [X] T022 [US1] Criar `web/src/core/LoginPage.tsx`: formulário com e-mail e senha (`autoComplete` `username`/`current-password`), aviso "Sua sessão expirou. Entre novamente." quando `expired=1`, mensagem de erro da API (401 e 429), botão desabilitado enquanto envia, e redirecionamento para `next` somente se começar com `/` e não com `//` (senão `/`); se já logado, redireciona direto
- [X] T023 [US1] Alterar `web/src/App.tsx`: rota pública `/login` (LoginPage) e as rotas do layout dentro de `RequireAuth`, tudo dentro de um elemento raiz que renderiza `AuthProvider` (precisa estar dentro do router para usar `useNavigate`)
- [X] T024 [P] [US1] Adicionar estilos da tela de login (cartão centralizado, responsivo) em `web/src/index.css`

**Checkpoint**: História 1 funcional e testável sozinha (testes T015–T017 verdes, roteiro 3 e 4.1–4.4 do quickstart)

---

## Fase 4: História 2 – Sair do Acervo (P1)

**Objetivo**: ver o e-mail conectado e sair invalidando a sessão

**Teste independente**: entrar, sair e confirmar que telas e API voltam a exigir login, inclusive com o cookie antigo

### Testes da História 2

- [X] T025 [US2] Adicionar a `api/test/controllers/api/v1/sessions_controller_test.rb`: `DELETE /api/v1/session` → 204, registro `Session` apagado e cookie removido; reutilizar o cookie antigo depois → 401; `DELETE` sem login → 401; com duas sessões do mesmo usuário, sair de uma mantém a outra válida

### Implementação da História 2

- [X] T026 [US2] Adicionar a ação `destroy` em `api/app/controllers/api/v1/sessions_controller.rb`: chama `terminate_session` e responde `204`
- [X] T027 [US2] Alterar `web/src/core/Layout.tsx`: mostrar `user.email_address` e um botão **Sair** na barra lateral (que chama `logout()` do `useAuth` e navega para `/login`), com estilos em `web/src/index.css` funcionando também no layout mobile

**Checkpoint**: Histórias 1 e 2 funcionando juntas

---

## Fase 5: História 3 – Proteção contra tentativas repetidas (P2)

**Objetivo**: recusar logins depois de 10 tentativas em 3 minutos da mesma origem

**Teste independente**: 11 tentativas seguidas → a 11ª é recusada mesmo com a senha certa

### Testes da História 3

- [X] T028 [US3] Adicionar a `api/test/controllers/api/v1/sessions_controller_test.rb`: 10 POSTs com senha errada seguidos de 1 com a senha certa → o último responde 429 `{ error: "Muitas tentativas. Aguarde alguns minutos e tente novamente." }`; depois de `travel 3.minutes + 1.second`, o login com a senha certa volta a funcionar (201)

### Implementação da História 3

- [X] T029 [US3] Adicionar em `api/app/controllers/api/v1/sessions_controller.rb`: `rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render json: { error: "Muitas tentativas. Aguarde alguns minutos e tente novamente." }, status: :too_many_requests }`

**Checkpoint**: limite de tentativas ativo; mensagem 429 exibida na tela de login (já tratada em T022)

---

## Fase 6: História 4 – Administrar a conta pelo terminal (P2)

**Objetivo**: criar a conta e redefinir a senha por comandos interativos

**Teste independente**: criar a conta pelo terminal, entrar, redefinir a senha e verificar que só a nova funciona

### Testes da História 4

- [X] T030 [P] [US4] Criar `api/test/tasks/acervo_user_task_test.rb` (carrega as tarefas com `Rails.application.load_tasks` uma vez e simula entrada via `$stdin = StringIO`): criar conta sem usuários → sucesso; segunda criação → recusa com "Nesta versão o Acervo tem um único usuário"; senha curta ou confirmação diferente → recusa com erro em português; `reset_password` muda a senha, encerra as sessões e informa a quantidade; e-mail inexistente → "Nenhum usuário com o e-mail …". As tarefas devem sinalizar falha com `exit 1` (capturar `SystemExit` no teste)

### Implementação da História 4

- [X] T031 [US4] Criar `api/lib/tasks/acervo_user.rake` com `namespace :acervo { namespace :user { task create: :environment; task reset_password: :environment } }`, seguindo `specs/001-email-password-auth/contracts/cli.md`: ler e-mail com `$stdin.gets`; ler senha com `$stdin.noecho(&:gets)` quando `$stdin.tty?` (senão `$stdin.gets`, para os testes); pedir confirmação; recusar a criação se `User.exists?` (FR-015); imprimir erros de validação com `full_messages`; usar `User#reset_password!` e imprimir "Senha redefinida. N sessão(ões) encerrada(s)."; nunca aceitar senha por argumento ou ENV

**Checkpoint**: todas as histórias funcionando de forma independente

---

## Fase 7: Polimento e itens transversais

- [X] T032 [P] Remover `api/db/seeds.rb` qualquer dependência de usuário (seeds continuam só com dados de Códigos) e documentar no `README.md` a criação da conta (`bin/rails acervo:user:create`), a redefinição de senha e a necessidade de `SECRET_KEY_BASE` em produção
- [X] T033 [P] Atualizar `CLAUDE.md`: seção "Autenticação" explicando que toda rota exige login por padrão, como liberar uma rota com `allow_unauthenticated_access`, que `Current.user` está disponível e que testes de request devem usar `sign_in_as`; incluir os comandos `acervo:user:*` na lista de comandos
- [X] T034 Validar: `ruby -c` em todos os arquivos Ruby alterados, aplicação das migrations e das consultas num PostgreSQL local, `npm run build` e `npm run lint` em `web/`; se `bundle install` estiver disponível, rodar `bin/rails test`. Caso contrário, registrar que os testes Rails devem ser rodados localmente antes do merge
- [ ] T035 Executar o roteiro de `specs/001-email-password-auth/quickstart.md` (quando o ambiente permitir) e conferir os critérios SC-001 a SC-007
  - **Pendente**: o ambiente da implementação não tinha acesso ao RubyGems (sem `bundle install`), então `bin/rails test` e o roteiro do quickstart precisam ser executados localmente antes do merge.

---

## Dependências e ordem de execução

### Entre fases

- **Setup (Fase 1)**: sem dependências
- **Fundação (Fase 2)**: depende do Setup; bloqueia todas as histórias
- **US1 (Fase 3)**: depende da Fundação. É o MVP
- **US2 (Fase 4)**: depende da US1 (mesmo controller; o botão Sair usa o `AuthProvider`)
- **US3 (Fase 5)**: depende da US1 (mesmo controller); independente da US2
- **US4 (Fase 6)**: depende só da Fundação (usa `User#reset_password!`); pode rodar em paralelo com a US1
- **Polimento (Fase 7)**: depois das histórias desejadas

### Dentro de cada história

- Testes escritos antes e falhando, depois a implementação
- Backend (controller/rotas) antes do frontend que o consome

### Oportunidades de paralelismo

- Fase 1: T002, T003 e T004 em paralelo depois de T001
- Fase 2: T007, T008 e T009 em paralelo depois das migrations; T012, T013 e T014 em paralelo
- US1: T015, T016 e T017 em paralelo; T020 e T024 em paralelo com o backend (T018–T019)
- US4 inteira em paralelo com a US1

### Exemplo de paralelismo (História 1)

```text
Em paralelo:
  T015 testes do SessionsController
  T016 teste de todas as rotas protegidas
  T017 testes do módulo Códigos autenticado
Depois, em paralelo:
  T018–T019 SessionsController + rotas (backend)
  T020 cliente da API (frontend)
```

---

## Estratégia de implementação

### MVP primeiro

1. Fase 1 e Fase 2
2. Fase 3 (US1): o Acervo fica protegido; já dá para criar o usuário pelo console enquanto a
   US4 não chega
3. **Parar e validar** com os testes e o roteiro do quickstart

### Entrega incremental

1. Setup + Fundação → base pronta
2. US1 → MVP protegido
3. US2 → logout
4. US3 → proteção contra força bruta (obrigatória antes de publicar na internet)
5. US4 → administração pelo terminal
6. Polimento → documentação e validação final
