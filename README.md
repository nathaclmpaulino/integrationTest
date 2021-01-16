<h1 align="center">
   Integration - Chat App
</h1>

<p align="center">
  <a href="#page_with_curl-sobre">Sobre</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#books-requisitos">Requisitos</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#gear-instalação">Instalação</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#rocket-iniciando-aplicação">Iniciando aplicação</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#computer-utilizando">Utilizando</a>&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
</p>


## :page_with_curl: Sobre
Este repositório contém uma automatização de ambiente, escrita em Shell Script, sendo responsável por subir todas as aplicações necessárias para que o sistema de chat composto pelo backend feito em Go, o frontend escrito em ReactJS e a database (Redis) funcione corretamente. 

***ShellScript***:  A escolha foi feita por se tratar uma linguaguem simples e presente em qualquer distribuição Linux. Todos os scripts bash que serão encontrados neste repositório foram desenvolvidos sobre uma distro Debian based (Ubuntu Server 20.04), portanto pode ter alguma inconsistência ao rodar estes scripts sobre outras distribuições, como as RHEL based.
 
***Decisões Arquiteturais***: O foco dessa arquitetura foi a resiliência geral do sistema e o mesmo obedece a seguinte estruturação conforme a imagem abaixo:

1. Os microsserviços estão rodando local sobre um Minikube que utiliza Docker como ferramenta de conteirização.
2. O Redis, embora seja um banco de dados, também está vinculado ao cluster rodando sobre um PVC. 
3. Todas as comunicações entre os microsserviços do cluster são feitas de forma interna ao invés de se usar qualquer tipo de endereçamento externo, com o intuito de prover maior velocidade de comunicação.

***Estruturação de Pastas***: A escolha por essa estrutura de pastas se deu principalmente pela escalabilidade do sistema! Para adicionar novos serviços a essa stack basta realizar os seguintes passos:
 1. Adicionar uma nova pasta que contém a estrutura do serviço no repositório. 
 2. Criar o Dockerfile necessário para rodar a aplicação sobre containers. 
 3. Construir a imagem e armazena-la em um Docker Registry utilizando o comando docker build e docker push 
 4. Escrever as definições de Kubernetes do serviço.
 5. Deploy da aplicação no Minikube utilizando o kubectl.

## :books: Requisitos
- Ter [**Git**](https://git-scm.com/) para clonar o projeto.
- Ter [**Docker**](https://www.docker.com/) instalado.
- Ter [**Minikube**](https://minikube.sigs.k8s.io/docs/) instalado.
- Ter [**Kubectl**](https://kubernetes.io/docs/tasks/tools/install-kubectl/) instalado.
- Ter uma conta em um docker registry de docker imagens no [**DockerHub**](https://hub.docker.com/).
- 
## :gear: Instalação de requisitos
``` bash
  # Clone o projeto: 
  $ git clone 
  
  # Execute o script requirements.sh que se encontra dentro da pasta infra, no subdiretório scripts:
  $ 
  
  # Execute o script environment.sh que se encontra dentro da pasta infra, no subdiretório scripts:
  $ 

```
Ao final desse passo, o usuário terá todos os requisitos mencionados instalados, bem como um cluster Minikube rodando em seu ambiente local. Quaisquer dúvidas sobre como usar um script, leia o README da pasta e, caso queira saber mais sobre o mesmo, utilize o seguinte comando: `$ ./<nome_do_script>.sh help`. 

## :rocket: Iniciando aplicação
```bash
  # Execute o script ci.sh que se encontra dentro da pasta infra, o subdiretório scripts:
  $ ./ci.sh

```

## :computer: Utilizando

 <h4> Ao final da execução do script anterior tem-se um ambiente funcional e funcionando localmente! Para acesssar os serviços via interface web, basta</h4>

GIF de funcionamento...

***GUI***: Caso prefira uma interface gráfica para acompanhar melhor o funcionamento do cluster, eu particularmente sugiro o [**Lens**](https://k8slens.dev/)! Basta baixar e instalar o Lens! Ao abrir o programa pela primeira vez, siga o passo a passo de descoberta de um cluster Kubernetes e você está livre para aproveitar essa nova interface!

<h1></h1>

<p align="center">Integrado com ❤️ por Nathã Paulino</p>
