<h1 align="center">
   Integration - Chat App
</h1>

<p align="center">
  <a href="#page_with_curl-sobre">Sobre</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#scroll-decisões-de-projeto">Decisões de Projeto</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#books-requisitos">Requisitos</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#gear-instalação-de-requisitos">Instalação</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#rocket-iniciando-aplicação">Iniciando aplicação</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#no_entry-computer-ambiente-local">Ambiente Local</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#computer-ambiente-de-produção">Produção</a>&nbsp;&nbsp;&nbsp;
</p>

## :page_with_curl: Sobre
Este repositório contém uma automatização de ambiente, escrita em Shell Script, sendo responsável por subir todas as aplicações necessárias para que o sistema de chat composto pelo backend feito em Go, o frontend escrito em ReactJS e a database (Redis) funcione corretamente. 

Este repositório roda este ambiente APENAS de forma local em um Minikube, na seção Em Produção é dito como incorporar esse código para um ambiente de produção com o intuito de preservar as melhores práticas!

***ShellScript***:  A escolha foi feita por se tratar uma linguaguem simples e presente em qualquer distribuição Linux. Os dois scripts bash presentes na pasta raíz do projeto são os responsáveis por integrar os serviços de forma automática e sem nenhum problema para o usuário. A seguir encontra-se a funcionalidade deles
  1. ci-cd.sh: Este script é responsável por fazer a tarefa de CI/CD da aplicação como um todo! Trata-se de um script completo, porém com webhook manual (vocês terão de o script para fazer a integração acontecer)! O passo a passo de execução desse script consta na seção <a href=#rocket-iniciando-aplicação> Iniciando aplicação</a>
  2. requirements.sh: Este script instala todos os requisitos necessários para rodar essa aplicação de forma local! A única coisa que se pede, é que tenha git instalado na máquina para buscar este repositório! 

***Estruturação de Pastas***: A escolha por essa estrutura de pastas se deu principalmente pela escalabilidade do sistema! Embora são microsserviços distintos (frontend, backend e database), podendo ficar separados em repositórios diferentes, optou-se por manter os todos no mesmo repositório para facilitar a integração com o script de CI!
 
Ao substituir este script para uma ferramenta de CI (GitLab, Jenkins, CircleCI, dentre outras), recomenda-se separar o repositório para fins de isolamento das aplicações!

Para adicionar novos serviços a essa stack basta realizar os seguintes passos:
 1. Adicionar uma nova pasta que contém a estrutura do serviço no repositório. 
 2. Criar o Dockerfile necessário para rodar a aplicação sobre containers. 
 3. Criar dentro da sua ferramenta de armazenamento de imagens, um novo repositório para suas imagens.
 4. Escrever as definições de Kubernetes do serviço, deixe parametrizado como consta nos outros arquivos.
 5. Incorporar o novo serviço ao script de CI. 
 6. Realizar o processo de teste, build e deploy utilizando o script de CI.

## :scroll: Decisões de Projeto

Conforme dito anteriormente, este projeto é criado sobre containers Docker e escalado para rodar sobre um Minikube, pensando em primeiro lugar instância na escalabilidade da aplicação!

***O projeto***: As aplicações descritas neste ambiente são extremamente sensíveis a falhas, ou seja, qualquer mínima perturbação de recursos incapacita o usuário de acessar, e qualquer perda de dados é caótica, dado que o tipo de produto que a empresa entrega é algo que aparenta ser muito similar a isso!

Com isso, houve a necessidade de se utilizar a orquestração de containers (Minikube) com o objetivo de resolver essas possíveis falhas, além de prover uma determinada segurança quanto a escalabilidade, caso algum serviço esteja sobrecarregado, o scaling de pods pode ser feito e o próprio Kubernetes é capaz de cuidar internamente do LoadBalancing entre os pods!

A seguir tem-se uma relação dos pods do sistema e como eles se comunicam pelo cluster! Outras decisões arquiteturais relativas a cada serviço separado serão explicadas em cada subseção deste tópico!

![Arquitetura do Clusher](https://i.imgur.com/OC5kuZW.png)

Neste esquema temos que:
  1. A comunicação entre o front e o backend, bem como o acesso externo ao ambiente, se dá através de um Ingress, mais precisamente sendo um [**NGINX Ingress Controller**](https://kubernetes.github.io/ingress-nginx/). Este recurso é capaz de liberar rotas externas para os serviços através de um NodePort. 
  2. A comunicação por sua vez entre o backend e o redis, por se tratar de uma comunicação extremamente sensível, e não querer disponibilizar uma rota para acesso externo do banco, o uso do endereçamento interno proporciona um grau a mais de segurança a este meio!
  3. Embora o Kubernetes seja uma aplicação voltada para conteúdos Stateless, o Redis ficou abarcado neste meio com o intuito de permitir uma possível estratégia de recuperação de falhas mais robusta, bem como aumentar a velocidade do mesmo! Para persistência dos dados, tem-se um PersistenceVolumeClaim (PVC) attachado a este serviço, para que o mesmo consiga armazenar os dados de uma forma definitiva.
  4. O próprio frontend da aplicação abarca um NGINX também para realizar controles estruturais importantes de headers, gerenciar múltiplas conexões para um mesmo pod, entre outros escopos mais avançados.

***Pontos de melhoria***: Neste contexto tem-se três possíveis pontos de melhoria a serem discutidos:

  1. As comunicações entre o front e o back não apresentam certificados TLS, sendo assim, elas são extremamente vulneráveis. Para se consertar este problema é necessário a presença de um servidor DNS, de modo que, a partir da resolução de DNS, seja gerenciável assim os certificados emitidos por CRDs como o [**cert-manager**](https://cert-manager.io/docs/).
  2. O segundo problema está no Redis, que o mesmo não apresenta nenhum mecanismo confiável de autenticação. Embora o mesmo esteja para uso privado dentro do cluster, colocar uma camada a mais de segurança nunca é demais!
  3. O Redis é um banco de gerência própria, self-hosted nesse caso, pois deve aguentar apenas 1000 mensagens, o que é relativamente pouco. A medida que o sistema cresce, este banco já começa a ter dificuldades de crescimento pelo lado da aplicação proposta. Uma sugestão é utilizar o Redis como uma cache de informações para serem persistidas em outro lugar futuramente, compartilhar a responsabilidade da mesma com um provedor cloud ou caso o volume de informações seja muito grande, pode-se aumentar o espaço alocado no PVC e utilizar um banco distribuído, caso o número de requisições seja muito grande!

## :books: Requisitos
- Ter [**Git**](https://git-scm.com/) para clonar o projeto.
- Ter [**Docker**](https://www.docker.com/) instalado.
- Ter [**Minikube**](https://minikube.sigs.k8s.io/docs/) instalado.
- Ter [**Kubectl**](https://kubernetes.io/docs/tasks/tools/install-kubectl/) instalado.
- Ter uma conta em um docker registry de docker imagens no [**DockerHub**](https://hub.docker.com/).

## :gear: Instalação de requisitos
``` bash
  # Clone o projeto: 
  $ git clone https://github.com/nathaclmpaulino/integrationTest.git
  
  # Execute o script requirements.sh que se encontra na raiz do repositório:
  $ ./requirements.sh run
  
  # Utilize o comando abaixo para rodar docker sem permissão de super usuário (sudo), e após ele, 
  # reinicie o computador (no caso de VM) ou feche o terminal e abra outro (caso PC) 
  #para que as mudanças tenham sido concluídas.
  $ newgrp docker

  # Execute a segunda etapa do script de requirements. Esta parte é responsável por deixar um 
  # minikube running em seu ambiente local e também em fornecer o IP do cluster Minikube
  $ ./requirements.sh config

  # Adicione este IP juntamente ao seu arquivo /etc/hosts. Este comando vai ser necessário para 
  # permitir que o Nginx IngressController criar uma rota de acesso ao seu navegador. 
  # Estes dois comandos precisarão de privilégios de super usuário!
  root# echo "<IP obtido na penultima linha> frontend.cluster" >> /etc/hosts
  root# echo "<IP obtido na penultima linha> backend.cluster" >> /etc/hosts

```
Ao final desse processo, você terá um Minikube rodando local na sua máquina com o config do Kubernetes diretamente apontado para ele e também com os addons de storage e ingresses funcionando. 

Segue uma imagem de como seu arquivo /etc/hosts deve ficar na máquina!

![Imgur](https://i.imgur.com/dPtlvo4.png)

Estes dois levam um tempo para serem deployados, mas é de extrema importância que esperem que o script termine com sucesso! 

A partir daqui é extremamente recomendado que você tenha acesso a uma dashboard do Kubernetes! Como isso é extremamente pessoal, mas eu gosto de usar o [**Lens**](https://k8slens.dev/). 

Se você estiver rodando em ambiente Linux que contenha o snap, use `sudo snap install kontena-lens --classic` para realizar o download do programa! Siga o processo de descoberta do cluster até ter acesso ao cluster de acordo com a imagem

![Imgur](https://i.imgur.com/N13sIMo.png)

***Resolvendo alguns erros do Minikube***:

Caso seja necessário, reinicie o Pod do CoreDNS para remover erro de ReadinessProbe do container e também pode excluir os dois Pods do tipo Job após os Jobs estiverem terminados!

![Imgur](https://i.imgur.com/gfLTpdu.png)

Agora basta continuar com o processo de iniciando a aplicação para que você tenha acesso aos serviços que compõem o cluster!

## :rocket: Iniciando aplicação
```bash
  # Execute as três etapas de CI!
  
  # Uso: ./ci-cd.sh pipeline SERVICE_NAME [USERNAME] [ACCESS_TOKEN] [REGISTRY_ADDRESS] [REGISTRY_NAME] [REACT_APP_BACKEND_WS] e [REACT_APP_BACKEND_URL]

  $ ./ci-cd.sh pipeline redis 

  $ ./ci-cd.sh pipeline backend <USERNAME> <ACCESS_TOKEN> nathapaulino backend-chatapp  

  $ ./ci-cd.sh pipeline frontend <USERNAME> <ACCESS_TOKEN> nathapaulino frontend-chatapp ws://backend.cluster http://backend.cluster

  # Caso queira testar somente aquele serviço (juntamente com os arquivos k8s), basta realizar o seguinte comando!
  # Uso: ./ci-cd.sh test SERVICE_NAME [REGISTRY_ADDRESS] [REGISTRY_NAME] [REACT_APP_BACKEND_WS] e [REACT_APP_BACKEND_URL]

  $ ./ci-cd.sh test redis

  $ ./ci-cd.sh test backend nathapaulino backend-chatapp

  $ ./ci-cd.sh test frontend nathapaulino frontend-chatapp http://backend.cluster ws://backend.cluster
```
Este script precisa de muitos parâmetros, pois ele foi construído para ser o mais universal possível, a ideia aqui era de prover um esquema de CI/CD, ainda sim que manual, funcionasse de forma que fosse possível outra pessoa qualquer utilizar, desde que a mesma esteja rodando sobre um Minikube! 

Os exemplos mostrados acima são de como rodar este script com as minhas próprias configurações do DockerHub! Os conteúdos das variáveis USERNAME e ACCESS_TOKEN podem ser pedidas para o dono do repositório (ou encontrados no corpo do email) porque trata-se de uma informação de controle de acesso, e portanto, extremamente sensível!

O conteúdo de REGISTRY_ADDRESS e REGISTRY_NAME se dão da seguinte forma, considerando a seguinte linha de um arquivo de Deployment.
```bash
    #...
    spec:
      containers:
        name: frontend
        image: ${REGISTRY_ADDRESS}/${REGISTRY_NAME}:${TAG}
    #...
```
A variável denominada TAG será gerada de forma aleatória pelo script, com isso, garante-se o flush da imagem no Deployment! 

O deploy do redis, por sua vez, usa a docker image pública do redis, não sendo necessário um repositório no registry de imagens do DockerHub.

Ao final da execução, vocês terão um cluster com mais ou menos esse formato:

![Imgur](https://i.imgur.com/PLeV9WO.png)

## :no_entry: :computer: Ambiente local

Ao final da execução do script anterior tem-se um ambiente funcional! Para acessar é só usar o endpoint `frontend.cluster/`. Lembrando que ao escrever os IPs no /etc/hosts conforme feito na etapa de Instalação de requisitos, você permitiu a criação de endpoints específicos externos (LoadBalancers) para o mapeamento interno do cluster! 

Conforme dito anteriormente, a comunicação entre o pod do backend e o pod do redis se dá internamente, por IP e porta do serviço! Assim cria-se uma camada a mais de proteção ao banco!

## :computer: Ambiente de Produção

A seguir temos a última seção responsável por mapear as mudanças para um ambiente de produção! Este ambiente será pensado em uma infraestrutura cloud na AWS!

O desenho a seguir indica uma visão arquitetural da plataforma sobre essas circunstâncias de produção, levando em consideração os seguintes pontos:
  1. Escalabilidade;
  2. Segurança;
  3. Resiliência;
  4. CI/CD;

![Imgur](https://i.imgur.com/JTVvj98.png)

Este seria uma visão geral do cluster, e como funcionaria o ambiente do mesmo em cloud! Os números indicam o caminho de dados de uma possível request ao ambiente! 

Tecnologias e discussão alto nível das estrututras:
  1. A criação de estruturas primárias para deploy de um cluster (VPC, Route53, S3 Buckets);
  2. O uso de [**Kops**](https://github.com/kubernetes/kops) ou [**Kubeadm**](https://github.com/kubernetes/kubeadm) ou [**EKS**](https://aws.amazon.com/pt/eks/) para deploy de um novo cluster com o uso de [**Autoscaling Groups**](https://aws.amazon.com/pt/autoscaling/) e [**Spot Instances**](https://aws.amazon.com/pt/ec2/spot/);
  3. O uso de [**Helm**](https://helm.sh/) para deploy das estruturas importantes!
  4. A adição via [**Helm**](https://helm.sh/) das principais estruturas de fluxo de instâncias, o [**Cluster Autoscaler**](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) e o [**Spot Termination Handler**](https://github.com/kube-aws/kube-spot-termination-notice-handler), garantindo escalabilidade; 
  5. O deploy do serviço de proxy reverso do [**Traefik**](https://traefik.io/) substituindo o NGINX Ingress Controller;
  6. O deploy do [**cert-manager**](https://cert-manager.io/docs/) para gestão de certificados TLS, na imagem é representado pelas secrets vinculadas aos IngressRoutes;
  7. O deploy dos pods do front e do back sobre o cluster, utilizando agora [**IngressRoute**](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/) como gerenciador de endpoints!
  8. O deploy do Redis sobre uma estrutura independente de gerenciamento como o [**ElastiCache**](https://aws.amazon.com/pt/elasticache/), e o back pode realizar comunicação (mostrado pelas linhas pontilhadas no serviço e fazer armazenamento de dados).

Com isso, se atinge os conceitos de escalabilidade, segurança (através do Traefik), resiliência pelo próprio orquestrador e o CI/CD pode ser uma instância na mesma VPC, se for self hosted ou ter permissão para acessar a API do Kubernetes. Fora isso, deve-se fechar os Security Groups do cluster permitindo só alguns específicos para permitir operações de gerência, consolidando assim um ambiente isolado, onde na imagem se é representado pelo retângulo arrendondado.

Todas as mudanças aqui mencionadas podem ser desenvolvidas e aplicadas via [**Terraform**](https://www.terraform.io/docs/index.html) + [**Ansible**](https://docs.ansible.com/ansible/latest/index.html) com o intuito de prover um maior controle da infraestrutura além de também possibilitar a integração de CI/CD neste processo, dando maior velocidade as tarefas!

<h1></h1>

<p align="center">Integrado por Nathã Paulino</p>
