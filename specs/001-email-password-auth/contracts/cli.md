# Contrato: comandos de terminal

Executados em `api/`. Interativos: a senha é digitada sem eco e pedida duas vezes. Nunca é
aceita por argumento ou variável de ambiente.

## `bin/rails acervo:user:create`

```
$ bin/rails acervo:user:create
E-mail: voce@exemplo.com
Senha (mín. 12 caracteres):
Confirme a senha:
Usuário voce@exemplo.com criado. Entre em http://localhost:5173/login
```

| Situação | Saída | Código de saída |
|---|---|---|
| Sucesso | mensagem de criação | `0` |
| Já existe um usuário | "Já existe um usuário (x@y.com). Nesta versão o Acervo tem um único usuário." | `1` |
| Senha curta, confirmação diferente ou e-mail inválido | erros de validação em português | `1` |

## `bin/rails acervo:user:reset_password`

```
$ bin/rails acervo:user:reset_password
E-mail: voce@exemplo.com
Nova senha (mín. 12 caracteres):
Confirme a nova senha:
Senha redefinida. 2 sessão(ões) encerrada(s).
```

| Situação | Saída | Código de saída |
|---|---|---|
| Sucesso | confirmação e número de sessões encerradas | `0` |
| E-mail não encontrado | "Nenhum usuário com o e-mail x@y.com." | `1` |
| Senha inválida ou confirmação diferente | erros em português | `1` |
