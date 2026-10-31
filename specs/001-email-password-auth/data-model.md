# Modelo de dados: Autenticação com e-mail e senha

Tabelas do núcleo, sem prefixo de módulo: autenticação pertence ao núcleo, não a um módulo
(princípio I).

## User (`users`)

| Campo | Tipo | Regras |
|---|---|---|
| `id` | bigint | PK |
| `email_address` | string | obrigatório; normalizado (`strip` + `downcase`); único (índice único); formato de e-mail válido |
| `password_digest` | string | obrigatório; gerado por `has_secure_password` (bcrypt) |
| `created_at`, `updated_at` | datetime | |

**Validações**
- Senha: mínimo de 12 caracteres (FR-017); máximo de 72 bytes (limite do bcrypt).
- `has_secure_password` exige confirmação quando ela é informada (usada pelas tarefas Rake).

**Relacionamentos**
- `has_many :sessions, dependent: :destroy`

**Comportamentos**
- `User.authenticate_by(email_address:, password:)`: usado no login, com tempo de resposta
  constante para e-mail existente ou não (FR-004).
- Redefinição de senha: atualiza `password` e apaga todas as `sessions` do usuário (FR-016).

**Fora desta feature**: ligação com dados dos módulos (`user_id` em `codes_*`), papéis e
permissões.

## Session (`sessions`)

| Campo | Tipo | Regras |
|---|---|---|
| `id` | bigint | PK |
| `user_id` | bigint | obrigatório; FK para `users`, `on_delete: :cascade`; indexado |
| `token` | string | obrigatório; único; gerado por `has_secure_token` |
| `ip_address` | string | origem do login |
| `user_agent` | string | navegador do login |
| `last_active_at` | datetime | obrigatório; atualizado no máximo 1 vez por hora |
| `created_at`, `updated_at` | datetime | |

**Ciclo de vida**

```
[login válido] → ativa ──(requisição: >1h desde last_active_at)──→ ativa (last_active_at = agora, cookie renovado)
                  │
                  ├──(30 dias sem uso)────────→ expirada → apagada no próximo acesso (401)
                  ├──(logout)─────────────────→ apagada
                  └──(senha redefinida)───────→ apagada (todas as do usuário)
```

**Regras**
- `expired?` → `last_active_at < 30.days.ago`.
- Várias sessões por usuário são permitidas (vários dispositivos).

## Current (não persistido)

`ActiveSupport::CurrentAttributes` com `session` e `user` (delegado de `session`), definido pelo
concern `Authentication` a cada requisição.
