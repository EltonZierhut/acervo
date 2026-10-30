# Quickstart: validar a preparação para produção

Contrato de execução: [contracts/runtime.md](contracts/runtime.md). Guia completo de publicação
para o dono: `docs/deploy-gcp.md`.

## 1. Testes e build (sem Docker)

```bash
cd api && bundle install && bin/rails test     # inclui os testes da SPA (SpaController)
cd ../web && npm run build && npm run lint
```

## 2. Imagem local com Docker

Pré-requisito: `api/Gemfile.lock` gerado (`cd api && bundle install`).

```bash
docker compose up -d                           # PostgreSQL local
docker build -t acervo .

docker run --rm -p 8080:8080 \
  -e DATABASE_URL=postgresql://postgres:postgres@host.docker.internal:5432/acervo_prod_local \
  -e SECRET_KEY_BASE=$(cd api && bin/rails secret) \
  acervo
```

(No Linux, adicione `--add-host=host.docker.internal:host-gateway`. Crie antes o banco
`acervo_prod_local` com `createdb` ou pelo `psql`.)

Esperado:
- Os logs mostram as migrations rodando e depois o Puma escutando na porta 8080.
- `curl -i http://localhost:8080/up` → 200.
- `curl -i http://localhost:8080/` → 200 com o HTML da interface e o cabeçalho
  `Strict-Transport-Security` (a imagem assume HTTPS; no Cloud Run o HTTP é redirecionado pela
  plataforma).
- `curl -i -H 'Accept: text/html' http://localhost:8080/codigos/projetos` → 200 com o HTML da
  interface e `Cache-Control: no-cache`.
- `curl -i http://localhost:8080/api/v1/naoexiste` → 404.
- Login pelo navegador em `http://localhost:8080`: o cookie de sessão é `Secure` em produção. Os
  navegadores atuais costumam aceitá-lo em `localhost`, mas se algum não aceitar, isso é esperado;
  a validação definitiva do login é no Cloud Run, que é HTTPS.
- Sem `-e SECRET_KEY_BASE`: o container termina com a mensagem de variáveis ausentes.

## 3. Publicação

Seguir `docs/deploy-gcp.md`. Esperado: `bin/deploy-gcp` termina mostrando a URL
`https://acervo-...run.app`, a tela de login abre e o login funciona com a conta criada pelo
`acervo:user:create` apontado para o Neon.
