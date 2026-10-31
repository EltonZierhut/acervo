# Quickstart: validar a autenticação

Guia para provar que a feature funciona de ponta a ponta. Contratos em
[contracts/session-api.md](contracts/session-api.md) e [contracts/cli.md](contracts/cli.md);
entidades em [data-model.md](data-model.md).

## Pré-requisitos

```bash
docker compose up -d
cd api && bundle install && bin/rails db:migrate
cd ../web && npm install
```

## 1. Testes automatizados

```bash
cd api && bin/rails test          # inclui: todas as rotas /api/v1 respondem 401 sem login (SC-001)
cd web && npm run build && npm run lint
```

Esperado: tudo verde.

## 2. Criar a conta (história 4)

```bash
cd api && bin/rails acervo:user:create      # informe e-mail e senha
bin/rails acervo:user:create                # 2ª vez: deve recusar (FR-015)
```

## 3. Proteção da API (história 1)

Com `bin/rails server` rodando:

```bash
curl -i localhost:3000/api/v1/codes/snippets          # 401 {"error":"Não autenticado"}
curl -i localhost:3000/up                             # 200

curl -i -c /tmp/c.txt -H 'Content-Type: application/json' \
  -d '{"email_address":"voce@exemplo.com","password":"<senha>"}' \
  localhost:3000/api/v1/session                       # 201 + Set-Cookie: session_token=...; HttpOnly; SameSite=Lax

curl -i -b /tmp/c.txt localhost:3000/api/v1/codes/snippets   # 200
curl -i -b /tmp/c.txt -X DELETE -H 'Content-Type: application/json' localhost:3000/api/v1/session   # 204
curl -i -b /tmp/c.txt localhost:3000/api/v1/codes/snippets   # 401 (sessão invalidada)
```

## 4. Interface (histórias 1 e 2)

Com `npm run dev` em `web/`:

1. Abra `http://localhost:5173/codigos/projetos`: vai para a tela de login.
2. Erre a senha: mensagem genérica "E-mail ou senha inválidos".
3. Entre com a senha certa: volta para `/codigos/projetos`.
4. Feche e reabra o navegador: continua logado.
5. Confira o e-mail na barra lateral, clique em **Sair**: volta ao login. Voltar no navegador
   não mostra dados.

## 5. Limite de tentativas (história 3)

Faça 11 `POST /api/v1/session` com senha errada em menos de 3 minutos: a 11ª retorna `429`,
mesmo com a senha certa.

## 6. Redefinir senha (história 4)

```bash
bin/rails acervo:user:reset_password
```

Esperado: a sessão do navegador cai (a próxima ação leva ao login com "Sua sessão expirou"), a
senha antiga falha e a nova funciona.
