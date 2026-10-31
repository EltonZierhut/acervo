# Publicar o Acervo no Google Cloud (Cloud Run + Cloud SQL)

O app roda no **Google Cloud Run** e o banco PostgreSQL no **Cloud SQL**, os dois em **São Paulo**. Depois
de configurado, **cada merge na `main` é publicado sozinho** pelo GitHub Actions, se os testes passarem.

```
PR  →  CI (testes, lint, build, imagem)
merge na main  →  CI  →  imagem no Artifact Registry  →  Cloud Run  →  confere /up
```

A configuração é feita uma vez e leva de 20 a 30 minutos.

> **O banco tem custo fixo:** o Cloud SQL fica ligado e cobra mesmo sem uso. Veja o passo 7.

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

## 2. Configurar o Google Cloud e o GitHub

Instale o [Google Cloud CLI (`gcloud`)](https://cloud.google.com/sdk/docs/install) e o
[GitHub CLI (`gh`)](https://cli.github.com). Depois, na raiz do repositório:

```bash
gcloud auth login
gh auth login
GCP_PROJECT=SEU_PROJETO_ID bin/setup-gcp
```

Ele cria:

- a instância `acervo-db` no Cloud SQL (PostgreSQL 16, a mesma versão de desenvolvimento e do CI), com
  backups diários mantidos por 7 dias, proteção contra exclusão e o banco e o usuário `acervo`. Ela só
  aceita conexões pelo conector do Cloud SQL, sem redes autorizadas;
- o repositório de imagens `acervo`, que apaga imagens com mais de 30 dias e mantém as 5 mais recentes;
- os segredos `DATABASE_URL` e `SECRET_KEY_BASE` no Secret Manager, com valores gerados na hora;
- a conta `acervo-runtime`, usada pelo app, que só lê os dois segredos e se conecta ao banco;
- a conta `acervo-deployer`, usada pelo GitHub Actions para publicar;
- o login do GitHub no Google (Workload Identity Federation), aceito só para a `main` deste
  repositório. Nenhuma chave fica guardada no GitHub;
- as variáveis `GCP_PROJECT_ID`, `GCP_WORKLOAD_IDENTITY_PROVIDER` e `GCP_DEPLOYER_SERVICE_ACCOUNT`
  no repositório, que ativam a publicação.

---

## 3. Primeira publicação

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

## 4. Criar sua conta de acesso

Precisa do Docker. O comando se conecta ao banco de produção pelo Cloud SQL Auth Proxy:

```bash
gcloud auth application-default login   # só na primeira vez
bin/prod-rails acervo:user:create
```

Abra a URL do serviço e entre com o e-mail e a senha que você acabou de cadastrar. Para redefinir a
senha depois, use `bin/prod-rails acervo:user:reset_password`.

---

## 5. Publicar uma nova versão

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

## 6. Ver logs

```bash
gcloud run services logs read acervo --region southamerica-east1 --limit 100
```

Ou no console: *Cloud Run → acervo → Logs*.

---

## 7. Custos esperados

| Item | Custo |
|---|---|
| Cloud SQL | **pago, sem plano gratuito permanente.** A máquina `db-f1-micro`, o disco de 10 GB e os backups ficam em torno de US$ 10 a 20 por mês em São Paulo (estimativa) |
| Cloud Run | dentro do uso gratuito mensal para um usuário (2 milhões de requisições e cotas de CPU e memória). São Paulo tem preço de faixa 2, mas o desconto gratuito vale para todas as regiões. |
| Artifact Registry (imagens) | pode gerar centavos pelo armazenamento; a limpeza automática mantém poucas imagens |
| GitHub Actions | gratuito em repositório público |

Confira os valores na [calculadora do Google](https://cloud.google.com/products/calculator) e, depois
do primeiro mês, na fatura real. Os créditos de conta nova cobrem o início.

**Comportamento esperado:** o primeiro acesso depois de um tempo sem uso demora alguns segundos (o
container iniciando). O banco fica sempre ligado. A máquina `db-f1-micro` tem CPU compartilhada e não
tem SLA do Google: serve para uso pessoal, não para carga alta.

**Para reduzir o custo:** a instância pode ser desligada quando não for usar o Acervo. O site para de
funcionar enquanto isso, e o disco e os backups continuam sendo cobrados:

```bash
gcloud sql instances patch acervo-db --activation-policy NEVER    # desliga
gcloud sql instances patch acervo-db --activation-policy ALWAYS   # liga
```

**Backups:** a restauração volta ao backup diário escolhido, e os dados depois dele se perdem. A
restauração a um ponto no tempo está desligada por custar mais; ative com
`gcloud sql instances patch acervo-db --enable-point-in-time-recovery` se precisar.

---

## 8. Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| O job `deploy` aparece como ignorado | variáveis do repositório ausentes | passo 2 |
| `unauthorized_client` ou `attribute condition` no login do Google | execução fora da `main` ou repositório renomeado | publique a partir da `main`; se renomeou, atualize a condição do provider |
| `Permission denied` em `iam.serviceAccounts.actAs`, `run` ou no envio da imagem | permissão ausente ou ainda propagando | aguarde alguns minutos e rode `bin/setup-gcp` de novo |
| `Permission denied on secret` | a conta do app não lê o segredo | rode `bin/setup-gcp` de novo |
| Logs com `Variáveis de ambiente obrigatórias ausentes` | segredo não informado ao serviço | confira `--set-secrets` e os nomes dos segredos |
| Erro de conexão com o banco (`Cloud SQL`, socket em `/cloudsql`) | instância desligada, conta sem `cloudsql.client` ou `--add-cloudsql-instances` errado | ligue a instância (passo 7) e rode `bin/setup-gcp` de novo |
| `bin/prod-rails` não conecta | credenciais locais ausentes ou expiradas, ou conta sem acesso ao banco | `gcloud auth application-default login` |
| Login não funciona (volta para a tela de login) | `SECRET_KEY_BASE` mudou entre versões | mantenha o mesmo segredo; trocar a chave encerra todas as sessões |
| `Muitas tentativas` | limite de 10 tentativas em 3 minutos | aguarde alguns minutos |
