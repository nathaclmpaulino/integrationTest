#!/bin/bash 

# Este script é responsável por fazer toda a lógica de testes e deploy
# das aplicações no Minikube!
# 
# Caso queira saber como ele funciona, use o comando ./ci-cd.sh help

function create_tag_image() {
  export TAG
  TAG= sudo head /dev/urandom | tr -dc 'a-z0-9' | fold -w 10 | head -n 1
}

# Parâmetros: <SERVICE_NAME> <REGISTRY_ADDRESS> <REGISTRY_NAME> <REACT_APP_BACKEND_URL> <REACT_APP_BACKEND_WS> <TAG>

function test_service() {
  export SERVICE_NAME=$1
  export REGISTRY_ADDRESS=$2
  export REGISTRY_NAME=$3
  export REACT_APP_BACKEND_URL=$4
  export REACT_APP_BACKEND_WS=$5
  export VALUE=$6
  local TAG
  echo "Iniciando os testes!"
  if [[ $VALUE == "" ]];
  then
    TAG=$(create_tag_image)
  else
    TAG=$VALUE
  fi;
  echo $TAG
  case $SERVICE_NAME in
    frontend)
      if ! (docker build --build-arg REACT_APP_BACKEND_WS=$REACT_APP_BACKEND_WS --build-arg REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL -f ./$SERVICE_NAME/Dockerfile.test ./$SERVICE_NAME ) ;
      then
        echo "Falha no teste + container docker do $SERVICE_NAME!"
        exit 2
      elif ! (envsubst < $PWD/$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-ingress.yml | kubectl apply --validate=true --dry-run=client -f - &&  
      envsubst < $PWD/$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME.yml | kubectl apply --validate=true --dry-run=client -f- );
      then
        echo "Falha nas definições de K8s do $SERVICE_NAME!"
        exit 2
      fi;
      ;;
    backend)
      if ! (envsubst < $PWD/$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-ingress.yml | kubectl apply --validate=true -f - &&
      envsubst < $PWD/$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-config.yml | kubectl apply --validate=true --dry-run=client -f - &&
      envsubst < $PWD/$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME.yml | kubectl apply --validate=true --dry-run=client -f - );
      then
        echo "Falha nas definições de K8s do $SERVICE_NAME!"
        exit 3
      fi;
      ;;
    redis)
      if ! kubectl apply --validate=true --dry-run=client -f ./database/$SERVICE_NAME/k8s-$SERVICE_NAME.yml ;
      then
        echo "Falha nas definições de K8s do $SERVICE_NAME!"
        exit 4
      fi;
      ;;
    *)
      echo "Serviço não existente! Consulte ./ci-cd.sh help para mais informações!"
      exit 1
      ;;
  esac
  echo "Testes realizados com sucesso!"
  return 0
}

# Parâmetros: <USERNAME> <ACCESS_TOKEN>
function login_dockerhub() {
  echo "Login Dockerhub"
  export USERNAME=$1
  export ACCESS_TOKEN=$2
  if ! (docker login --username $USERNAME --password $ACCESS_TOKEN) ;
  then
    echo "Não foi possível logar no DockerHub! Confira suas credenciais de acesso!"
    return 5
  fi;
  echo "Login realizado com sucesso!"  
  return 0
}

function deploy_service() {
  echo "Start deploy stage"
  export SERVICE_NAME=$1 
  export REGISTRY_ADDRESS=$2
  export REGISTRY_NAME=$3
  export TAG=$4
  case $SERVICE_NAME in 
    frontend)
      envsubst < $PWD/$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-ingress.yml | kubectl apply -f - 
      envsubst < $PWD/$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME.yml | kubectl apply -f -
      ;;
    backend)
      envsubst < $PWD/$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-ingress.yml | kubectl apply -f -  
      envsubst < $PWD/$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME.yml | kubectl apply -f -  
      envsubst < $PWD/$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-config.yml | kubectl apply -f -  
      ;;
    redis)
      kubectl apply -f $PWD/database/$SERVICE_NAME/k8s-$SERVICE_NAME.yml
      ;;
    *)
      echo "Serviço não encontrado! Use ./ci-cd.sh help para mais informações!"
      exit 1
      ;;
  esac
  echo "Success deploy stage!"
	return 0
}         


# Parâmetros: <SERVICE_NAME> <USERNAME> <ACCESS_TOKEN> <REGISTRY_ADDRESS> <REGISTRY_NAME>
# <REACT_APP_BACKEND_URL> <REACT_APP_BACKEND_WS> <TAG>

function push_dockerhub() {
  export SERVICE_NAME=$1
  export USERNAME=$2
  export ACCESS_TOKEN=$3
  export REGISTRY_ADDRESS=$4
  export REGISTRY_NAME=$5
  export REACT_APP_BACKEND_URL=$6
  export REACT_APP_BACKEND_WS=$7
  export TAG=$8

  if ! login_dockerhub $USERNAME $ACCESS_TOKEN
  then 
    echo "Não foi possível logar no DockerHub"
    exit 5
  fi;
  TAG=$(create_tag_image)
  case $SERVICE_NAME in 
		frontend)
      docker build -t $TAG --build-arg REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL --build-arg REACT_APP_BACKEND_WS=$REACT_APP_BACKEND_WS -f ./$SERVICE_NAME/Dockerfile ./$SERVICE_NAME 
			docker tag $TAG $REGISTRY_ADDRESS/$REGISTRY_NAME:$TAG
			docker push $REGISTRY_ADDRESS/$REGISTRY_NAME:$TAG
			;;
		backend)
			docker build -t $TAG -f ./$SERVICE_NAME/Dockerfile ./$SERVICE_NAME/
			docker tag $TAG $REGISTRY_ADDRESS/$REGISTRY_NAME:$TAG
			docker push $REGISTRY_ADDRESS/$REGISTRY_NAME:$TAG
			;;
		*)
			echo "Serviço não encontrado! Use ./ci-cd.sh help para mais informações!"
			exit 1
			;;
	esac
	return 0
}

# Parâmetros: <SERVICE_NAME> <USERNAME> <ACCESS_TOKEN> <REGISTRY_ADDRESS> <REGISTRY_NAME> 
# <REACT_APP_BACKEND_URL> <REACT_APP_BACKEND_WS>
function pipeline() {
  export SERVICE_NAME=$1
  export USERNAME=$2
  export ACCESS_TOKEN=$3
  export REGISTRY_ADDRESS=$4
  export REGISTRY_NAME=$5
  export REACT_APP_BACKEND_URL=$6
  export REACT_APP_BACKEND_WS=$7
  export TAG
  TAG=$(create_tag_image)
 	case $SERVICE_NAME in
		frontend)
      echo $TAG
			test_service $SERVICE_NAME $REGISTRY_ADDRESS $REGISTRY_NAME $REACT_APP_BACKEND_URL $REACT_APP_BACKEND_WS $TAG
			push_dockerhub $SERVICE_NAME $USERNAME $ACCESS_TOKEN $REGISTRY_ADDRESS $REGISTRY_NAME $REACT_APP_BACKEND_URL $REACT_APP_BACKEND_WS $TAG
			deploy_service $SERVICE_NAME $REGISTRY_ADDRESS $REGISTRY_NAME $TAG
			;;
		backend)
      echo $TAG
			test_service $SERVICE_NAME $REGISTRY_ADDRESS $REGISTRY_NAME $REACT_APP_BACKEND_URL $REACT_APP_BACKEND_WS $TAG
      push_dockerhub $SERVICE_NAME $USERNAME $ACCESS_TOKEN $REGISTRY_ADDRESS $REGISTRY_NAME $REACT_APP_BACKEND_URL $REACT_APP_BACKEND_WS $TAG
			deploy_service $SERVICE_NAME $REGISTRY_ADDRESS $REGISTRY_NAME $TAG
			;;
		redis)
			test_service $SERVICE_NAME $REGISTRY_ADDRESS $REGISTRY_NAME $TAG
			deploy_service $SERVICE_NAME $REGISTRY_ADDRESS $REGISTRY_NAME $TAG
			;;
		*)
			echo "Serviço não encontrado!"
			exit 1
	esac
	return 0
}

# Script se inicia aqui!

case $# in
  1)
    if [[ $1 == 'help' ]];
    then
      echo "Este script contém diversas funcionalidades separadas sobre funções! Ele é capaz de
realizar o deploy do cluster Kubernetes localmente (Minikube), o processo de build, testes 
(em aplicações que contém testes), além do deploy de cada um dos serviços separado!
	
Uso: ./ci-cd.sh [COMMAND] [ARGS]

A lista de possíveis COMMAND estão descritas abaixo e o que cada um exemplo de uso:

test: Realiza os testes da aplicação em si, bem como a validação dos arquivos de definição do 
Kubernetes dentro das pastas de cada serviço!
Uso: ./ci-cd.sh test [SERVICE_NAME] [REGISTRY_ADDRESS] [REGISTRY_NAME] [REACT_APP_BACKEND_URL] [REACT_APP_BACKEND_WS]
		
pipeline: Este comando realiza o deploy de uma das aplicações!
Uso: ./ci-cd.sh pipeline [SERVICE_NAME] [USERNAME] [ACCESS_TOKEN] [REGISTRY_ADDRESS] [REGISTRY_NAME] 
[REACT_APP_BACKEND_URL] [REACT_APP_BACKEND_WS]

OBS:
O arguemento dado por SERVICE_NAME assume apenas três valores: frontend backend ou redis e todos os argumentos
fornecidos são obrigatórios!
ESTE SCRIPT ASSUME QUE SEU ARQUIVO DE CONFIGURAÇÃO DO MINIKUBE SE SITUA NO DIRETÓRIO PADRÃO: ~/.kube/config"
    else
      echo "Use: ./ci-cd.sh help para mais informações!"
    fi;
    ;;
  2)
    if [[ $1 == 'test' && $2 == 'redis' ]];
    then
      test_service $2
    elif [[ $1 == 'pipeline' && $2 == 'redis' ]];
    then 
      pipeline $2
    else
      echo "Leia o README.md e use ./ci-cd.sh help para obter ajuda!"  
    fi;
    ;;
  4)
    if [[ $1 == 'test' && $2 == 'backend' ]];
    then
      test_service $2 $3 $4
    else
      echo "Leia o README.md para saber como rodar o teste do $2!"
    fi;
    ;;
  6)
    if [[ $1 == 'test' && $2 == 'frontend' ]];
    then
      test_service $2 $3 $4 $5 $6
    elif [[ $1 == 'pipeline' && $2 == 'backend' ]]; 
    then
      pipeline $2 $3 $4 $5 $6
    else
      echo "Leia o README.md ou use ./ci-cd.sh help para mais informações!"
    fi; 
    ;;
  8)
    if [[ $1 == 'pipeline' && $2 == 'frontend' ]];
    then
      pipeline $2 $3 $4 $5 $6 $7 $8
    else
      echo "Use ./ci-cd.sh help para mais informações!"
    fi;
    ;;
  *)
    echo "Use: ./ci-cd.sh help para mais informações!"
    ;;
esac
