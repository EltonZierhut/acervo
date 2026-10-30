# Pesquisa (Fase 0): Autenticação com e-mail e senha

Cada item registra **Decisão**, **Justificativa** e **Alternativas consideradas**.

## R1. Base da autenticação

- **Decisão**: seguir a estrutura do gerador de autenticação do Rails 8
  (`bin/rails generate authentication`): models `User`, `Session` e `Current`, concern
  `Authentication`, `SessionsController` e `has_secure_password` (gem `bcrypt`). Os arquivos são
  escritos seguindo essa estrutura, adaptados para o modo API: sem views, sem
  `PasswordsController` e sem `PasswordMailer`.
- **Justificativa**: é a solução oficial do framework, sem gems de autenticação de terceiros
  (princípio II). O código fica no projeto e é fácil de evoluir para multiusuário, 2FA ou
  passkeys. A separação entre `User` e `Session` atende ao FR-018.
- **Alternativas**: Devise (muitos recursos que não serão usados, mais mágica, e as views HTML
  não servem a uma SPA); Rodauth (poderoso, mas é uma dependência e um modelo mental a mais);
  JWT (sessão sem estado não permite invalidar no logout nem na redefinição de senha, o que
  violaria o FR-008 e o FR-016, além de exigir guardar o token no navegador).
- **Observação**: o ambiente onde o plano foi escrito não tem acesso ao RubyGems. Se der para
  rodar o gerador localmente, use a saída dele como referência para conferir os arquivos, mas
  não aplique as views nem o fluxo de senha por e-mail.

## R2. Transporte da sessão: cookie assinado `httpOnly`

- **Decisão**: o login cria um registro `Session` com um token aleatório (`has_secure_token`) e
  grava `cookies.signed[:session_token]` com `httponly: true`, `same_site: :lax`,
  `secure: Rails.env.production?` e validade de 30 dias, renovada com o uso. Em modo API é
  preciso adicionar o middleware `ActionDispatch::Cookies` e incluir `ActionController::Cookies`
  no `ApplicationController`. Não é usado o `session` do Rails (nenhum session store).
- **Justificativa**: o React e a API ficam no mesmo endereço (proxy do Vite no desenvolvimento,
  Rails servindo o build em produção), então o navegador envia o cookie automaticamente. O
  `httpOnly` impede que scripts na página leiam a credencial (FR-007). O token aleatório, em vez
  do id, não expõe ids sequenciais e serve para tokens de API no futuro.
- **Alternativas**: token no `localStorage` (vulnerável a XSS, contraria o FR-007); session
  store do Rails (`cookie_store`) sem tabela de sessões (não permite invalidar sessões no
  servidor, contraria o FR-008 e o FR-016).

## R3. Proteção contra CSRF

- **Decisão**: (1) cookie `SameSite=Lax`, que não é enviado em `POST`, `PATCH` ou `DELETE`
  disparados por outros sites; (2) requisições que alteram dados (`POST`, `PUT`, `PATCH`,
  `DELETE`) só são aceitas com `Content-Type: application/json`, recusadas com `415` caso
  contrário; (3) o CORS continua liberando apenas a origem do próprio frontend.
- **Justificativa**: formulários HTML de outro site não conseguem enviar JSON sem preflight de
  CORS, e o preflight é negado. Combinado com o `SameSite=Lax`, cobre CSRF sem tokens extras
  na SPA (princípio II). O cliente `web/src/core/api.ts` já envia JSON em todas as requisições.
- **Alternativas**: `protect_from_forgery` com token CSRF entregue à SPA (funciona, mas exige
  um endpoint e um cabeçalho a mais sem ganho real neste cenário); `SameSite=Strict` (quebraria
  o acesso ao abrir um link do Acervo a partir de outro site).

## R4. Expiração por inatividade (30 dias)

- **Decisão**: a tabela `sessions` tem `last_active_at`. A cada requisição autenticada, se a
  sessão passou de 30 dias sem uso, ela é apagada e a resposta é `401`. Caso contrário, se
  `last_active_at` tem mais de 1 hora, ele é atualizado e o cookie renovado por mais 30 dias.
- **Justificativa**: atende ao FR-006 sem escrever no banco a cada requisição. A validação é
  feita no servidor; a validade do cookie é só um complemento.
- **Alternativas**: cookie `permanent` do gerador (20 anos, sem expiração por inatividade, não
  atende ao FR-006); cookie de sessão de navegador (perde o login ao fechar o navegador,
  contraria o cenário 5 da história 1).

## R5. Limite de tentativas de login

- **Decisão**: `rate_limit to: 10, within: 3.minutes, only: :create` no `SessionsController`
  (recurso nativo do Rails 8, por endereço IP), respondendo `429` com mensagem em português.
  `cache_store` definido como `:memory_store` em desenvolvimento, teste e produção (hoje o
  desenvolvimento usa `:null_store`, que desativaria o limite).
- **Justificativa**: o `rate_limit` usa o cache do Rails; em memória é suficiente para uma
  instância com um processo (uso pessoal). Atende ao FR-010 e ao SC-004.
- **Alternativas**: Rack::Attack (dependência a mais); `solid_cache` ou Redis (necessários só
  com vários processos ou servidores; registrar como evolução na feature de deploy, caso o
  Puma rode com mais de um worker).

## R6. Comandos de terminal

- **Decisão**: tarefas Rake `bin/rails acervo:user:create` e
  `bin/rails acervo:user:reset_password`, em `lib/tasks/acervo_user.rake`, que pedem e-mail e
  senha de forma interativa, lendo a senha com `IO#noecho` (`io/console`) e pedindo
  confirmação. A regra de conta única (FR-015) fica na tarefa de criação, não no model.
- **Justificativa**: senha nunca passa por argumento nem variável de ambiente, então não fica no
  histórico do shell (SC-006). Manter a regra fora do model preserva o FR-018.
- **Alternativas**: `bin/rails console` (não guia o usuário, e é fácil errar); argumentos na
  linha de comando (senha no histórico).

## R7. Infraestrutura de testes

- **Decisão**: criar a base de testes com Minitest (`test/test_helper.rb`, fixtures e
  `ActionDispatch::IntegrationTest`), já que o projeto ainda não tem testes. Incluir um helper
  `sign_in_as(user)` e um teste que percorre todas as rotas em `/api/v1`, exceto as de sessão, e
  verifica que todas respondem `401` sem login (SC-001). Os testes existentes do módulo Códigos
  passam a fazer login antes.
- **Justificativa**: o princípio V exige request tests, e o SC-001 exige cobertura de todas as
  rotas. O teste por introspecção de rotas cobre automaticamente módulos futuros.
- **Alternativas**: RSpec (dependência a mais; o Minitest é o padrão do Rails).

## R8. Frontend

- **Decisão**: em `web/src/core/` (núcleo, porque todos os módulos dependem disso):
  - `auth.tsx`: `AuthProvider` e o hook `useAuth`, com o usuário atual consultado em
    `GET /api/v1/session` na inicialização;
  - `RequireAuth`: protege o layout e redireciona para `/login?next=<rota>`;
  - `LoginPage.tsx`: tela de login;
  - `api.ts`: ao receber `401`, notifica o `AuthProvider`, que leva ao login guardando a rota
    atual e avisando que a sessão expirou (FR-011).
  O `Layout` mostra o e-mail conectado e o botão **Sair**. O `fetch` usa
  `credentials: 'same-origin'` (padrão), e nenhum token é guardado no JavaScript.
- **Justificativa**: mantém os módulos sem saber nada de autenticação (princípio I) e não exige
  bibliotecas novas (princípio II).
- **Alternativas**: React Query ou bibliotecas de autenticação (dependências sem necessidade).

## R9. Prontidão para multiusuário (FR-018)

- **Decisão**: `users` é uma tabela comum (sem restrição de linha única), `sessions` referencia
  `user_id`, e `Current.user` fica disponível nos controllers. Os dados do módulo Códigos **não**
  ganham `user_id` agora.
- **Justificativa**: na feature de multiusuário basta adicionar `user_id` às tabelas dos módulos,
  atribuir os dados existentes ao primeiro usuário e filtrar por `Current.user`, sem mexer na
  autenticação.
- **Alternativas**: adicionar `user_id` já (fora do escopo da spec e sem uso real hoje).
