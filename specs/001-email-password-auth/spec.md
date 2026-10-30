# Especificação da feature: Autenticação com e-mail e senha

**Branch da feature**: `001-email-password-auth`

**Criada em**: 2026-10-30

**Status**: Rascunho

**Entrada**: Descrição do usuário: "Autenticação com e-mail e senha para o Acervo (opção 1). Hoje o sistema é de um único usuário: não há tela de cadastro; o usuário é criado por comando no terminal, e a senha pode ser redefinida pelo terminal (sem envio de e-mail por enquanto). Sessão por cookie seguro (httpOnly) no mesmo domínio, já que o Rails servirá o React. Todas as rotas da API e todas as telas exigem login, exceto a tela de login e o health check. Limitar tentativas de login para evitar força bruta. Logout. É provável que no futuro o Acervo tenha mais pessoas usando, então a solução deve permitir evoluir para múltiplos usuários (cada um com seus próprios dados) sem retrabalho grande, mas multiusuário e isolamento de dados por usuário NÃO fazem parte desta feature. Evoluções futuras possíveis (fora do escopo): 2FA com app autenticador, passkeys, login com Google, cadastro e recuperação de senha por e-mail."

## Cenários de uso e testes *(obrigatório)*

### História 1 - Proteger o Acervo e entrar com e-mail e senha (Prioridade: P1)

O dono do Acervo abre o sistema e, antes de ver qualquer informação, precisa informar e-mail e
senha. Com credenciais corretas, ele entra e usa o Acervo normalmente. Sem login, nenhuma
informação (códigos, projetos, módulos) fica visível nem pode ser alterada, seja pelas telas,
seja acessando a API diretamente.

**Por que esta prioridade**: sem isso o Acervo não pode ser publicado na internet, porque
qualquer pessoa com o endereço poderia ler, alterar e apagar os dados. É o motivo da feature.

**Teste independente**: com um usuário existente, abrir o sistema sem estar logado (deve
aparecer só a tela de login), tentar acessar dados pela API sem sessão (deve ser negado) e
então entrar com e-mail e senha corretos (o conteúdo aparece).

**Cenários de aceitação**:

1. **Dado** que não estou logado, **quando** abro qualquer endereço do Acervo, **então** vejo a
   tela de login e nenhum dado do sistema.
2. **Dado** que estou na tela de login, **quando** informo e-mail e senha corretos, **então**
   entro no Acervo e sou levado à página que tentei abrir originalmente (ou à inicial).
3. **Dado** que estou na tela de login, **quando** informo e-mail ou senha incorretos, **então**
   vejo uma mensagem genérica de que as credenciais são inválidas, sem indicar qual dos dois
   campos está errado.
4. **Dado** que não estou logado, **quando** faço uma requisição direta para qualquer recurso de
   dados da API, **então** recebo uma resposta de "não autenticado", sem nenhum dado.
5. **Dado** que entrei no Acervo, **quando** fecho o navegador e volto a abri-lo dentro do prazo
   de validade da sessão, **então** continuo logado.

---

### História 2 - Sair do Acervo (Prioridade: P1)

Logado, o dono vê com qual e-mail está conectado e pode sair. Ao sair, a sessão deixa de valer:
voltar com o botão do navegador ou reaproveitar a sessão antiga não dá acesso aos dados.

**Por que esta prioridade**: é parte mínima de um login seguro, especialmente ao usar o Acervo
num computador que não é seu.

**Teste independente**: entrar, sair e confirmar que as telas e a API voltam a exigir login,
inclusive ao tentar reutilizar a sessão encerrada.

**Cenários de aceitação**:

1. **Dado** que estou logado, **quando** olho a interface, **então** vejo o e-mail da conta
   conectada e uma opção de sair.
2. **Dado** que estou logado, **quando** escolho sair, **então** volto para a tela de login.
3. **Dado** que saí, **quando** tento acessar telas ou dados (inclusive voltando no navegador),
   **então** o acesso é negado e preciso entrar de novo.

---

### História 3 - Proteção contra tentativas repetidas de senha (Prioridade: P2)

Se alguém tentar adivinhar a senha com muitas tentativas seguidas, o Acervo passa a recusar
novas tentativas por um tempo, dificultando ataques de força bruta.

**Por que esta prioridade**: importante quando o sistema estiver na internet, mas o login
funciona sem ela. Pode ser entregue logo depois das histórias P1.

**Teste independente**: errar a senha repetidamente até ultrapassar o limite e verificar que
novas tentativas, inclusive com a senha correta, são recusadas até o fim do período de espera.

**Cenários de aceitação**:

1. **Dado** que já houve 10 tentativas de login em menos de 3 minutos vindas da mesma origem,
   **quando** é feita mais uma tentativa, **então** ela é recusada com uma mensagem pedindo para
   tentar novamente mais tarde, mesmo que a senha esteja correta.
2. **Dado** que as tentativas foram bloqueadas, **quando** o período de espera termina, **então**
   é possível tentar entrar de novo normalmente.

---

### História 4 - Administrar a conta pelo terminal (Prioridade: P2)

Como não existe tela de cadastro nem recuperação por e-mail, quem tem acesso ao servidor cria a
conta do dono e, se ele esquecer a senha, define uma nova, usando comandos no terminal.

**Por que esta prioridade**: necessário para existir o primeiro usuário e para não perder o
acesso. Pode ser exercitado de forma independente das telas.

**Teste independente**: criar a conta pelo terminal, entrar com ela, redefinir a senha pelo
terminal e verificar que só a senha nova funciona.

**Cenários de aceitação**:

1. **Dado** que não existe nenhuma conta, **quando** executo o comando de criação informando
   e-mail e senha, **então** a conta é criada e consigo entrar com ela.
2. **Dado** que já existe uma conta, **quando** tento criar outra, **então** o comando recusa e
   explica que, nesta versão, o Acervo tem um único usuário.
3. **Dado** que existe uma conta, **quando** executo o comando de redefinição de senha para o
   e-mail dela, **então** a senha antiga deixa de funcionar, a nova passa a funcionar e todas as
   sessões abertas daquela conta são encerradas.
4. **Dado** que informo uma senha que não atende às regras mínimas, **quando** executo a criação
   ou a redefinição, **então** o comando recusa e explica a regra.
5. **Dado** que a senha é digitada no terminal, **quando** executo os comandos, **então** a senha
   não aparece na tela nem fica gravada no histórico de comandos.

---

### Casos de borda

- A sessão expira enquanto o dono está usando o Acervo (por exemplo, ao salvar um código): o
  sistema leva à tela de login avisando que a sessão expirou e, depois de entrar, volta à tela
  em que ele estava. O que ainda não tinha sido salvo pode ser perdido.
- E-mail digitado com letras maiúsculas ou espaços nas pontas: é tratado como o mesmo e-mail.
- O mesmo dono logado em dois dispositivos ao mesmo tempo: as duas sessões funcionam de forma
  independente; sair de uma não encerra a outra.
- Tentativa de login com um e-mail que não existe: mesma resposta e mensagem de credenciais
  inválidas, para não revelar quais e-mails têm conta.
- Comando de redefinição de senha para um e-mail inexistente: o terminal informa que a conta
  não foi encontrada (quem usa o terminal já tem acesso total ao servidor).
- Acesso ao endereço de verificação de saúde do sistema (usado pela hospedagem): continua
  respondendo sem login e sem expor dados.

## Requisitos *(obrigatório)*

### Requisitos funcionais

- **FR-001**: O sistema DEVE exigir autenticação para acessar qualquer tela e qualquer recurso
  de dados, com exceção da tela de login, da ação de entrar e da verificação de saúde do sistema.
- **FR-002**: O sistema DEVE permitir entrar informando e-mail e senha.
- **FR-003**: O sistema DEVE tratar o e-mail sem diferenciar maiúsculas e minúsculas e
  ignorando espaços nas pontas.
- **FR-004**: Em caso de falha no login, o sistema DEVE exibir uma mensagem genérica, idêntica
  para e-mail inexistente e senha errada.
- **FR-005**: O sistema DEVE guardar as senhas apenas de forma irreversível (nunca a senha em
  si), de modo que nem quem tem acesso ao banco de dados consiga lê-las.
- **FR-006**: O sistema DEVE manter o usuário logado entre visitas até que ele saia ou até que
  a sessão fique 30 dias sem uso.
- **FR-007**: A credencial de sessão DEVE ser inacessível a scripts executados na página e só
  DEVE ser enviada em conexões seguras quando o sistema estiver em produção.
- **FR-008**: O sistema DEVE permitir sair, invalidando a sessão no servidor, de forma que ela
  não possa ser reaproveitada.
- **FR-009**: O sistema DEVE mostrar, enquanto o usuário estiver logado, o e-mail da conta
  conectada.
- **FR-010**: O sistema DEVE recusar novas tentativas de login vindas da mesma origem depois de
  10 tentativas em 3 minutos, até que o período termine, informando que é preciso aguardar.
- **FR-011**: Ao receber uma resposta de "não autenticado" durante o uso, a interface DEVE levar
  à tela de login e, depois de entrar, retornar à página em que o usuário estava.
- **FR-012**: Requisições não autenticadas aos recursos de dados DEVEM receber uma resposta de
  "não autenticado" padronizada, sem conter dados do sistema.
- **FR-013**: O sistema NÃO DEVE oferecer cadastro de contas pela interface.
- **FR-014**: Deve existir um comando de terminal para criar a conta, pedindo e-mail e senha; a
  senha DEVE ser digitada sem aparecer na tela.
- **FR-015**: Nesta versão, o comando de criação DEVE recusar a criação de uma segunda conta.
- **FR-016**: Deve existir um comando de terminal para redefinir a senha de uma conta pelo
  e-mail; a redefinição DEVE encerrar todas as sessões abertas daquela conta.
- **FR-017**: Senhas DEVEM ter no mínimo 12 caracteres; criação e redefinição com senhas mais
  curtas DEVEM ser recusadas com explicação.
- **FR-018**: A conta DEVE ser modelada como uma entidade própria, separada das sessões, e o
  sistema DEVE estar preparado para ter várias contas no futuro (por exemplo, sem supor no
  modelo que só existe uma). O limite de uma conta (FR-015) é uma regra desta versão, e não uma
  limitação da estrutura.

### Entidades principais

- **Usuário (conta)**: quem acessa o Acervo. Atributos: e-mail (único, normalizado), senha
  protegida de forma irreversível, datas de criação e atualização. Pode ter várias sessões.
- **Sessão**: um acesso ativo de um usuário a partir de um dispositivo. Atributos: usuário
  dono, data de criação, data do último uso (para a expiração por inatividade) e informações
  básicas do dispositivo (como endereço de origem e navegador), úteis para auditoria e para
  encerrar sessões. Encerrada ao sair, ao expirar ou na redefinição de senha.

## Critérios de sucesso *(obrigatório)*

### Resultados mensuráveis

- **SC-001**: 100% dos recursos de dados do sistema recusam acesso sem login, verificado por
  testes automatizados que cobrem todas as rotas de dados.
- **SC-002**: O dono consegue entrar no Acervo, desde abrir a tela de login até ver seus
  códigos, em menos de 15 segundos.
- **SC-003**: Depois de sair, 0 telas ou recursos de dados ficam acessíveis com a sessão antiga.
- **SC-004**: A 11ª tentativa de login em menos de 3 minutos vinda da mesma origem é recusada em
  100% dos casos.
- **SC-005**: A primeira conta pode ser criada pelo terminal, e uma senha redefinida, em menos de
  1 minuto cada, seguindo apenas as instruções do README.
- **SC-006**: Nenhuma senha aparece legível no banco de dados, em logs ou no histórico do terminal.
- **SC-007**: As funcionalidades atuais do módulo Códigos continuam funcionando sem mudanças
  para o usuário depois do login (todos os fluxos existentes passam).

## Premissas

- O Acervo terá um único usuário nesta versão. Multiusuário, com cada pessoa vendo apenas os
  próprios dados, é uma feature futura. Por isso esta feature não associa códigos e projetos a
  um usuário, e a criação de uma segunda conta é bloqueada (FR-015): sem isolamento de dados,
  uma segunda pessoa veria tudo.
- Quando o multiusuário for feito, os dados existentes serão atribuídos à primeira conta. Esta
  feature só precisa garantir que a conta seja uma entidade própria que permita isso (FR-018).
- Quem executa os comandos de terminal tem acesso administrativo ao servidor; não há
  autenticação adicional para esses comandos.
- A interface e os dados são servidos a partir do mesmo endereço em produção, o que permite usar
  uma sessão mantida pelo navegador. Indicação técnica do usuário, a confirmar no plano: sessão
  por cookie `httpOnly` no mesmo domínio, com o Rails servindo o build do React.
- O limite de tentativas é aplicado por origem da requisição (endereço de rede), seguindo o
  padrão do gerador de autenticação do Rails 8 (10 tentativas em 3 minutos).
- A expiração por 30 dias sem uso é um padrão razoável para um sistema pessoal; não há opção
  "lembrar de mim" nesta versão.
- Fora do escopo: cadastro pela interface, recuperação de senha por e-mail, verificação em duas
  etapas, passkeys, login com Google, tela para ver e encerrar sessões e qualquer isolamento de
  dados entre usuários.
- Dependência: a feature de deploy (Rails servindo o React) pode vir depois; em desenvolvimento,
  o proxy do Vite já serve interface e API pelo mesmo endereço, então a sessão funciona igual.
