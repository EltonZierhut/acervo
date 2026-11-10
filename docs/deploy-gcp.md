# Publicar o Acervo no Google Cloud (Cloud Run + Neon)

O app roda no **Google Cloud Run** e o banco PostgreSQL no **Neon**, os dois em **São Paulo**. Depois
de configurado, **cada merge na `main` é publicado sozinho** pelo GitHub Actions, se os testes passarem.

```
PR  →  CI (testes, lint, build, imagem)
merge na main  →  CI  →  imagem no Artifact Registry  →  Cloud Run  →  confere /up
```

A configuração é feita uma vez e leva de 20 a 30 minutos.

> **O banco é serverless:** o Neon desliga sozinho quando não está em uso e o uso pessoal cabe no plano
> gratuito. Veja o passo 8.

> Os comandos usam bash. No Windows, use o WSL ou o Git Bash.

---

## 1. Conta e projeto no Google Cloud

1. Crie a conta em https://cloud.google.com. Ela pede cartão; contas novas recebem US$ 300 de
   crédito por 90 dias.
2. No console, crie um projeto (ex.: `acervo`), confira se ele está ligado à conta de faturamento e
   anote o **ID do projeto**.
3. **Crie um alerta de orçamento antes de qualquer outra coisa:**
   *Faturamento → Orçamentos e alertas → Criar orçamento*. Use um valor baixo (ex.: R$ 10) com
   alertas em 50%, 90% e 100%. Ele só avisa por e-mail; não interrompe a cobrança.

---

## 2. Banco de dados no Neon

1. Crie a conta em https://neon.com e um projeto na região **AWS São Paulo (`aws-sa-east-1`)**, a mesma
   do Cloud Run. Outra região deixa cada consulta mais lenta.
2. No projeto, abra *Connect*, escolha a branch `production` e **desligue o connection pooling**. Copie a
   connection string direta (o host não tem `-pooler`). Ela termina com `sslmode=require`.

A conexão direta é a recomendada aqui: o serviço tem uma instância só, com poucas conexões, e as
migrations usam advisory locks, que não funcionam pelo pooler.

---

## 3. Configurar o Google Cloud e o GitHub

Instale o [Google Cloud CLI (`gcloud`)](https://cloud.google.com/sdk/docs/install) e o
[GitHub CLI (`gh`)](https://cli.github.com). Depois, na raiz do repositório:

```bash
gcloud auth login
gh auth login
GCP_PROJECT=SEU_PROJETO_ID bin/setup-gcp
```

Na primeira vez ele pede a connection string do Neon (passo 2), sem mostrá-la na tela. Ele cria:

- o repositório de imagens `acervo`, que apaga imagens com mais de 30 dias e mantém as 5 mais recentes;
- os segredos `DATABASE_URL` (a connection string do Neon) e `SECRET_KEY_BASE` (gerado na hora) no Secret Manager;
- a conta `acervo-runtime`, usada pelo app, que só lê os dois segredos;
- a conta `acervo-deployer`, usada pelo GitHub Actions para publicar;
- o login do GitHub no Google (Workload Identity Federation), aceito só para a `main` deste
  repositório. Nenhuma chave fica guardada no GitHub;
- as variáveis `GCP_PROJECT_ID`, `GCP_WORKLOAD_IDENTITY_PROVIDER` e `GCP_DEPLOYER_SERVICE_ACCOUNT`
  no repositório, que ativam a publicação.

---

## 4. Primeira publicação

```bash
gh workflow run deploy.yml --ref main
gh run watch
```

No fim do log do passo `bin/deploy-gcp` aparece a URL do serviço, algo como
`https://acervo-xxxxxxxxxx.southamerica-east1.run.app`. Ao iniciar, o app prepara o banco
automaticamente.

O que a publicação configura (veja `bin/deploy-gcp`):
- uma única instância (`--max-instances 1`), exigida pelo limite de tentativas de login;
- escala a zero quando não está em uso (`--min-instances 0`), sem cobrança parada;
- 512 MiB de memória e 1 CPU;
- `--allow-unauthenticated`: o endereço é acessível pela internet, e quem protege os dados é o
  login do Acervo.

---

## 5. Criar sua conta de acesso

Precisa do Docker. O comando lê a `DATABASE_URL` do Secret Manager e se conecta direto ao Neon:

```bash
bin/prod-rails acervo:user:create
```

Abra a URL do serviço e entre com o e-mail e a senha que você acabou de cadastrar. Para redefinir a
senha depois, use `bin/prod-rails acervo:user:reset_password`.

---

## 6. Publicar uma nova versão

Faça o merge do PR na `main`. Acompanhe em *Actions* no GitHub ou com `gh run watch`.

Se o CI falhar, nada é publicado. Se as migrations falharem ao iniciar, a nova versão não recebe
tráfego e a anterior continua no ar.

Para publicar da sua máquina, sem o GitHub Actions (precisa do Docker e de permissão na sua conta
do Google):

```bash
git switch main && git pull
bin/deploy-gcp
```

**Voltar a uma versão anterior:** *Console → Cloud Run → acervo → Revisões → Gerenciar tráfego*. As
migrations não são desfeitas, então confira se a versão anterior funciona com o banco atual. O
próximo merge na `main` volta a publicar a versão nova.

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
| Neon | o plano gratuito cobre o uso pessoal; confira os limites de armazenamento e de horas de computação em https://neon.com/pricing |
| Cloud Run | dentro do uso gratuito mensal para um usuário (2 milhões de requisições e cotas de CPU e memória). São Paulo tem preço de faixa 2, mas o desconto gratuito vale para todas as regiões. |
| Artifact Registry (imagens) | pode gerar centavos pelo armazenamento; a limpeza automática mantém poucas imagens |
| GitHub Actions | gratuito em repositório público |

Confira os valores na [calculadora do Google](https://cloud.google.com/products/calculator) e, depois
do primeiro mês, na fatura real.

**Comportamento esperado:** o primeiro acesso depois de um tempo sem uso demora alguns segundos: o
container do Cloud Run inicia e o Neon, que desliga quando fica parado, volta a ligar.

**Backups:** o Neon permite restaurar a branch para um ponto no tempo dentro da janela de histórico do
plano (*console → Backup & Restore*). Para guardar uma cópia fora dele:

```bash
pg_dump --format=custom --file acervo.dump "$(gcloud secrets versions access latest --secret DATABASE_URL)"
```

---

## 9. Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| O job `deploy` aparece como ignorado | variáveis do repositório ausentes | passo 3 |
| `unauthorized_client` ou `attribute condition` no login do Google | execução fora da `main` ou repositório renomeado | publique a partir da `main`; se renomeou, atualize a condição do provider |
| `Permission denied` em `iam.serviceAccounts.actAs`, `run` ou no envio da imagem | permissão ausente ou ainda propagando | aguarde alguns minutos e rode `bin/setup-gcp` de novo |
| `Permission denied on secret` | a conta do app não lê o segredo | rode `bin/setup-gcp` de novo |
| Logs com `Variáveis de ambiente obrigatórias ausentes` | segredo não informado ao serviço | confira `--set-secrets` e os nomes dos segredos |
| Erro de conexão com o banco (`connection refused`, `SSL`, `password authentication failed`) | `DATABASE_URL` errada, senha trocada no Neon ou cota do plano gratuito esgotada | confira no console do Neon e grave a connection string nova com `gcloud secrets versions add DATABASE_URL --data-file=-` |
| `bin/prod-rails` não conecta | login do `gcloud` expirado ou conta sem acesso ao segredo | `gcloud auth login` |
| Login não funciona (volta para a tela de login) | `SECRET_KEY_BASE` mudou entre versões | mantenha o mesmo segredo; trocar a chave encerra todas as sessões |
| `Muitas tentativas` | limite de 10 tentativas em 3 minutos | aguarde alguns minutos |
