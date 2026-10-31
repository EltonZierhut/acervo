# Publicar o Acervo no Google Cloud (Cloud Run + Neon)

Guia passo a passo para colocar o Acervo na internet. O app roda no **Google Cloud Run** e o
banco PostgreSQL no **Neon**, os dois em **São Paulo**.

Tempo estimado na primeira vez: 20 a 30 minutos. Depois, cada nova versão é um comando.

> Os comandos usam bash. No Windows, use o WSL ou o Git Bash.

---

## 0. Pré-requisitos

1. **Login pronto e testado.** A feature de autenticação (branch `001-email-password-auth`)
   precisa estar com os testes passando (`cd api && bin/rails test`) e integrada à `main`.
   **Nunca publique sem login**: qualquer pessoa com o endereço veria seus dados.
2. **`Gemfile.lock` versionado.** O build usa as versões travadas nele:

   ```bash
   cd api
   bundle install
   bundle lock --add-platform x86_64-linux   # necessário se seu computador for Mac ou ARM
   git add Gemfile.lock && git commit -m "Adiciona Gemfile.lock"
   ```

3. **Ferramentas:** [Google Cloud CLI (`gcloud`)](https://cloud.google.com/sdk/docs/install).
   O Docker é opcional (só para testar a imagem localmente).

---

## 1. Conta e projeto no Google Cloud

1. Crie a conta em https://cloud.google.com. Ela pede cartão; contas novas recebem US$ 300 de
   crédito por 90 dias.
2. No console, crie um projeto (ex.: `acervo`) e anote o **ID do projeto**.
3. **Crie um alerta de orçamento antes de qualquer outra coisa:**
   *Faturamento → Orçamentos e alertas → Criar orçamento*. Use um valor baixo (ex.: R$ 10) com
   alertas em 50%, 90% e 100%. Ele avisa por e-mail se algo sair do esperado.

No seu computador:

```bash
gcloud auth login
gcloud config set project SEU_PROJETO_ID

gcloud services enable run.googleapis.com artifactregistry.googleapis.com \
  cloudbuild.googleapis.com secretmanager.googleapis.com
```

Guarde o número do projeto numa variável (usado nos próximos passos):

```bash
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
```

`$SA` é a conta de serviço padrão: ela constrói a imagem e executa o app.

Dê a ela permissão para construir a imagem a partir do código (pode levar alguns minutos para
valer):

```bash
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA" --role=roles/run.builder
```

---

## 2. Banco de dados no Neon

1. Crie a conta em https://neon.com (não pede cartão).
2. Crie um projeto:
   - **Região:** AWS South America (São Paulo), `aws-sa-east-1`
   - **Versão do PostgreSQL:** a mais recente oferecida
3. Em *Connect*, copie a **connection string direta**: desligue a opção *Connection pooling*. A
   string começa com `postgresql://` e termina com `?sslmode=require`. O host **não** deve conter
   `-pooler`.

---

## 3. Guardar as credenciais no Secret Manager

As credenciais ficam no Google, nunca no código.

```bash
# Endereço do banco (cole a string do Neon entre as aspas)
printf '%s' 'postgresql://USUARIO:SENHA@HOST/neondb?sslmode=require' | \
  gcloud secrets create DATABASE_URL --data-file=-

# Chave que assina o cookie de login (gerada no seu computador)
printf '%s' "$(cd api && bin/rails secret)" | \
  gcloud secrets create SECRET_KEY_BASE --data-file=-

# Permite que o app leia os dois segredos
for secret in DATABASE_URL SECRET_KEY_BASE; do
  gcloud secrets add-iam-policy-binding "$secret" \
    --member="serviceAccount:$SA" --role=roles/secretmanager.secretAccessor
done
```

> Use `printf '%s'` (e não `echo`) para não gravar uma quebra de linha no fim do segredo.

---

## 4. Publicar

Na raiz do repositório, na branch `main`:

```bash
bin/deploy-gcp
```

- Na primeira vez, o `gcloud` pode perguntar se deve criar o repositório de imagens
  `cloud-run-source-deploy` em `southamerica-east1`: responda **Y**.
- O build leva alguns minutos. No fim aparece a URL do serviço, algo como
  `https://acervo-xxxxxxxxxx.southamerica-east1.run.app`.
- Ao iniciar, o app aplica as migrations no banco do Neon automaticamente.

O que o comando configura (veja `bin/deploy-gcp`):
- uma única instância (`--max-instances 1`), exigida pelo limite de tentativas de login;
- escala a zero quando não está em uso (`--min-instances 0`), sem cobrança parada;
- 512 MiB de memória e 1 CPU;
- `--allow-unauthenticated`: o endereço é acessível pela internet, e quem protege os dados é o
  login do Acervo.

---

## 5. Criar sua conta de acesso

Rode no seu computador, apontando para o banco do Neon:

```bash
cd api
DATABASE_URL='postgresql://USUARIO:SENHA@HOST/neondb?sslmode=require' \
  bin/rails acervo:user:create
```

Abra a URL do serviço e entre com o e-mail e a senha que você acabou de cadastrar.

Para redefinir a senha depois, use o mesmo formato com `bin/rails acervo:user:reset_password`.

> Coloque um espaço antes do comando (` DATABASE_URL=...`) para que ele não fique no histórico do
> terminal, se o seu shell estiver configurado para isso (`HISTCONTROL=ignorespace` no bash; no
> zsh, `setopt HIST_IGNORE_SPACE`).

---

## 6. Publicar uma nova versão

```bash
git switch main && git pull
bin/deploy-gcp
```

O Cloud Run troca a versão sem derrubar o site. Para voltar a uma versão anterior:
*Console → Cloud Run → acervo → Revisões → Gerenciar tráfego*.

---

## 7. Ver logs

```bash
gcloud run services logs read acervo --region southamerica-east1 --limit 100
```

Ou no console: *Cloud Run → acervo → Logs*.

---

## 8. Custos esperados

| Item | Custo |
|---|---|
| Cloud Run | dentro do uso gratuito mensal para um usuário (2 milhões de requisições e cotas de CPU e memória). São Paulo tem preço de faixa 2, mas o desconto gratuito vale para todas as regiões. |
| Neon | gratuito (1 GB de armazenamento, 100 horas de computação por mês) |
| Artifact Registry (imagens) | pode gerar centavos pelo armazenamento das imagens antigas; apague versões antigas no console se quiser |
| Cloud Build | os builds de cada publicação costumam caber na cota gratuita |

**Comportamento esperado:** o primeiro acesso depois de um tempo sem uso demora alguns segundos
(o container e o banco "acordando"). Os acessos seguintes são rápidos.

---

## 9. Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| Build falha com `api/Gemfile.lock não encontrado` | lock não versionado | passo 0.2 |
| Build falha em `bundle install` por plataforma | lock gerado num Mac/ARM | `bundle lock --add-platform x86_64-linux` e commit |
| Erro de permissão `run.builder` / build não inicia | permissão do passo 1 ainda propagando | aguarde alguns minutos e rode de novo |
| `Permission denied on secret` | falta o `add-iam-policy-binding` dos segredos | passo 3 |
| Logs com `Variáveis de ambiente obrigatórias ausentes` | segredo não informado ao serviço | confira `--set-secrets` e os nomes dos segredos |
| Erro de conexão com o banco ou SSL | string do Neon errada ou com `-pooler` | use a string direta com `sslmode=require` e atualize o segredo: `printf '%s' '...' \| gcloud secrets versions add DATABASE_URL --data-file=-`, depois publique de novo |
| Login não funciona (volta para a tela de login) | `SECRET_KEY_BASE` mudou entre versões | mantenha o mesmo segredo; trocar a chave encerra todas as sessões |
| `Muitas tentativas` | limite de 10 tentativas em 3 minutos | aguarde alguns minutos |
