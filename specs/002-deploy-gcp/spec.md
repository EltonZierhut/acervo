# Especificação da feature: Preparar o Acervo para publicação no Google Cloud

**Branch da feature**: `002-deploy-gcp`

**Criada em**: 2026-10-30

**Status**: Rascunho

**Entrada**: Descrição do usuário: "Preparar o código para publicar o Acervo no Google Cloud (Cloud Run em São Paulo, com banco PostgreSQL no Neon). Primeira etapa: deixar o projeto pronto para produção; a criação das contas e a publicação são feitas pelo usuário."

## Cenários de uso e testes *(obrigatório)*

### História 1 - Empacotar o Acervo como um único serviço publicável (Prioridade: P1)

O dono quer publicar o Acervo num único endereço de internet. A interface e os dados precisam
ser entregues pelo mesmo serviço, de forma que o login por cookie funcione e haja um só item
para publicar e manter.

**Por que esta prioridade**: sem um pacote único de produção não há o que publicar. É a base
das outras histórias.

**Teste independente**: construir o pacote de produção e executá-lo localmente apontando para um
banco PostgreSQL: a tela de login abre no endereço raiz, as rotas internas do app (ex.:
`/codigos/projetos`) carregam a interface ao serem abertas diretamente, e a API responde no
mesmo endereço.

**Cenários de aceitação**:

1. **Dado** o pacote de produção em execução, **quando** abro o endereço raiz, **então** vejo a
   interface do Acervo (tela de login, se não estiver logado).
2. **Dado** o pacote em execução, **quando** abro diretamente um endereço interno da interface
   (ex.: recarregar a página em `/codigos/projetos`), **então** a interface carrega, e não um erro.
3. **Dado** o pacote em execução, **quando** a interface chama a API, **então** as chamadas vão
   para o mesmo endereço e o login por cookie funciona.
4. **Dado** um endereço de API inexistente, **quando** é acessado, **então** a resposta é um erro
   de "não encontrado", e não a página da interface.

---

### História 2 - Configuração segura de produção (Prioridade: P1)

Em produção, o Acervo deve usar conexão segura, ler as credenciais do ambiente (endereço do
banco e chave de assinatura dos cookies) e nunca tê-las no código.

**Por que esta prioridade**: publicar sem isso exporia credenciais ou a sessão de login.

**Teste independente**: iniciar o pacote sem as credenciais (deve recusar a inicialização com
mensagem clara) e com as credenciais (deve iniciar); acessar por HTTP comum deve redirecionar
para HTTPS, exceto a verificação de saúde.

**Cenários de aceitação**:

1. **Dado** que as credenciais não foram fornecidas, **quando** o serviço inicia em produção,
   **então** ele falha logo no início com mensagem indicando o que falta.
2. **Dado** o serviço em produção, **quando** alguém acessa por HTTP comum, **então** é
   redirecionado para HTTPS; a verificação de saúde responde sem redirecionar.
3. **Dado** o serviço em produção, **quando** o usuário faz login, **então** o cookie de sessão
   só é enviado por conexão segura.
4. **Dado** o repositório, **quando** alguém o inspeciona, **então** não encontra senhas, chaves
   nem o endereço do banco de produção.

---

### História 3 - Atualizar o banco automaticamente ao publicar (Prioridade: P2)

Ao publicar uma nova versão, as alterações de estrutura do banco são aplicadas antes de o
serviço começar a atender, sem passos manuais.

**Por que esta prioridade**: evita esquecer migrations, mas o dono poderia rodá-las à mão.

**Teste independente**: publicar contra um banco vazio e verificar que as tabelas foram criadas e
o serviço atende; publicar de novo sem mudanças e verificar que nada é reaplicado.

**Cenários de aceitação**:

1. **Dado** um banco vazio, **quando** o serviço inicia, **então** todas as estruturas são
   criadas antes de atender requisições.
2. **Dado** um banco já atualizado, **quando** o serviço reinicia, **então** ele inicia
   normalmente sem alterar o banco.
3. **Dado** que a atualização do banco falha, **quando** o serviço inicia, **então** ele não
   passa a atender e o erro aparece nos logs.

---

### História 4 - Publicar com um comando documentado (Prioridade: P2)

O dono segue um guia passo a passo para criar as contas, guardar as credenciais e publicar com
um único comando, e sabe como criar sua conta de acesso no banco de produção.

**Por que esta prioridade**: o dono vai publicar sozinho; sem guia, o risco de erro e de custo
inesperado é alto.

**Teste independente**: seguir o guia do início ao fim numa conta nova e chegar ao Acervo
publicado com login funcionando.

**Cenários de aceitação**:

1. **Dado** o guia, **quando** o dono executa os passos, **então** chega a um endereço público do
   Acervo com HTTPS.
2. **Dado** o guia, **quando** o dono configura a conta, **então** cria um alerta de orçamento
   antes de publicar.
3. **Dado** o serviço publicado, **quando** o dono segue o passo de criação de conta, **então**
   consegue entrar no Acervo publicado.
4. **Dado** uma nova versão do código, **quando** o dono executa o mesmo comando de publicação,
   **então** a nova versão substitui a anterior.

---

### Casos de borda

- Recarregar a página numa rota interna da interface: deve carregar a interface (não 404).
- Requisição de arquivo estático inexistente (ex.: `/assets/nao-existe.js`): 404, sem devolver a
  página da interface.
- Banco "dormindo" (Neon desliga depois de inatividade): a primeira requisição pode demorar mais,
  mas deve ser atendida sem erro.
- Mais de uma instância do serviço: o limite de tentativas de login deixaria de valer entre
  instâncias; a publicação deve limitar o serviço a uma instância.
- Interface ainda não compilada no ambiente de desenvolvimento: abrir o endereço da API no
  navegador não deve quebrar; responde com aviso de que a interface roda pelo Vite.

## Requisitos *(obrigatório)*

### Requisitos funcionais

- **FR-001**: O projeto DEVE poder ser empacotado em uma única imagem de container contendo a API
  e a interface já compilada.
- **FR-002**: O serviço DEVE entregar a interface no endereço raiz e em qualquer rota de
  navegação que não seja da API, da verificação de saúde ou de arquivos estáticos.
- **FR-003**: Rotas da API inexistentes e arquivos estáticos inexistentes DEVEM responder
  "não encontrado", nunca a página da interface.
- **FR-004**: A página principal da interface NÃO DEVE ser guardada em cache pelo navegador
  (para que novas versões apareçam), enquanto arquivos estáticos com nome versionado DEVEM ter
  cache longo.
- **FR-005**: Em produção, o serviço DEVE ler o endereço do banco e a chave de assinatura de
  variáveis de ambiente e DEVE falhar na inicialização, com mensagem clara, se faltarem.
- **FR-006**: Em produção, o serviço DEVE exigir HTTPS (redirecionando HTTP), considerando que o
  HTTPS é terminado pela plataforma, exceto na verificação de saúde.
- **FR-007**: O serviço DEVE escutar na porta informada pela plataforma.
- **FR-008**: Ao iniciar, o serviço DEVE aplicar as alterações pendentes do banco antes de
  atender; se falhar, não deve atender.
- **FR-009**: A imagem DEVE rodar o serviço com um usuário sem privilégios de administrador.
- **FR-010**: Nenhuma credencial DEVE estar no repositório nem na imagem; arquivos locais
  sensíveis e artefatos de build DEVEM ser excluídos do repositório e da imagem.
- **FR-011**: O projeto DEVE incluir um comando de publicação que limite o serviço a uma
  instância e use as credenciais guardadas no gerenciador de segredos da plataforma.
- **FR-012**: O projeto DEVE incluir um guia de publicação em português cobrindo: criação da conta
  e do projeto, alerta de orçamento, banco no Neon (região São Paulo), cadastro das credenciais,
  publicação, criação da conta de acesso, atualização de versão e custos esperados.

### Entidades principais

Nenhuma entidade nova de dados.

## Critérios de sucesso *(obrigatório)*

### Resultados mensuráveis

- **SC-001**: Seguindo o guia, o dono publica o Acervo pela primeira vez em menos de 30 minutos.
- **SC-002**: Uma nova versão é publicada com 1 comando.
- **SC-003**: Com uso pessoal (um usuário), o custo mensal fica dentro das cotas gratuitas,
  exceto valores residuais de armazenamento de imagens, e um alerta avisa se passar do limite
  definido pelo dono.
- **SC-004**: 100% das rotas de navegação da interface carregam ao serem abertas diretamente.
- **SC-005**: Nenhuma credencial aparece no repositório nem nos logs.
- **SC-006**: Todos os testes automatizados existentes continuam passando.

## Premissas

- Plataforma escolhida pelo dono: Google Cloud Run na região de São Paulo; banco PostgreSQL
  gerenciado no Neon, região São Paulo (`aws-sa-east-1`).
- A feature 001 (autenticação) é pré-requisito e precisa estar concluída e com os testes passando
  antes da publicação; esta branch parte dela.
- Uma única instância basta para uso pessoal e mantém o limite de tentativas de login correto.
- A primeira requisição depois de um período sem uso pode levar alguns segundos (serviço e banco
  "acordando"); isso é aceito pelo dono em troca do custo próximo de zero.
- A conta de acesso em produção é criada rodando o comando de terminal do Acervo no computador do
  dono, apontado para o banco de produção.
- Fora do escopo: publicação automática pelo GitHub Actions, domínio próprio, backups além dos
  oferecidos pelo Neon e monitoramento.
