#!/bin/bash 

# Este script é responsável por fazer toda a lógica de testes e deploy
# das aplicações no Minikube!
# 
# Caso queira saber como ele funciona, use o comando ./ci-cd.sh help

# Parâmetros: <SERVICE_NAME> <REGISTRY_ADDRESS> <REGISTRY_NAME> <REACT_APP_BACKEND_URL> <REACT_APP_BACKEND_WS> <TAG>
function test_service() {
  local SERVICE_NAME=$1
  local REGISTRY_ADDRESS=$2
  local REGISTRY_NAME=$3
  local REACT_APP_BACKEND_URL=$4
  local REACT_APP_BACKEND_WS=$5
  local TAG=$6
  case $SERVICE_NAME in
    frontend)
      if ! docker build --build-arg REACT_APP_BACKEND_WS=$REACT_APP_BACKEND_WS --build-arg REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL -f ./$SERVICE_NAME/Dockerfile.test ./$SERVICE_NAME;
      then
        echo "Falha no teste + container docker do $SERVICE_NAME!"
        return 2
      elif ! eval "kubectl apply --validate=true --dry-run -f - <<EOF 
      $(cat ./$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-ingress.yml)
      ---
      $(cat ./$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME.yml)  
      EOF" 
      then
        echo "Falha nas definições de K8s!"
        return 3
      fi;
      ;;
    backend)
      if ! eval "kubectl apply --validate=true --dry-run -f - <<EOF 
      $(cat ./$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-ingress.yml)
      ---
      $(cat ./$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME.yml)
      ---
      $(cat ./$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-config.yml)  
      EOF"
      then
        echo "Falha nas definições de K8s do $SERVICE_NAME!"
        return 3
      fi;
      ;;
    redis)
      if ! eval "kubectl apply --validate=true --dry-run -f - <<EOF 
      $(cat ./database/$SERVICE_NAME/k8s-$SERVICE_NAME.yml)
      ---
      EOF"
      then
        echo "Falha nas definições de K8s do $SERVICE_NAME!"
        return 3
      fi;
      ;;
    *)
      echo "Serviço não existente! Consulte ./ci-cd.sh help para mais informações!"
      return 1
      ;;
  esac
  return 0
}

function deploy_service() {
  SERVICE_NAME=$1 
  REGISTRY_ADDRESS=$2
  REGISTRY_NAME=$3
  TAG=$4
  case $SERVICE_NAME in 
    frontend)
      eval "kubectl apply --validate=true --dry-run -f - <<EOF 
      $(cat ./$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-ingress.yml)
      ---
      $(cat ./$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME.yml)  
      EOF"
      ;;
    backend)
      eval "kubectl apply --validate=true --dry-run -f - <<EOF 
      $(cat ./$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-ingress.yml)
      ---
      $(cat ./$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME.yml)
      ---
      $(cat ./$SERVICE_NAME/kubernetes/k8s-$SERVICE_NAME-config.yml)  
      EOF"
      ;;
    redis)
      eval "kubectl apply --validate=true --dry-run -f - <<EOF 
      $(cat ./database/$SERVICE_NAME/k8s-$SERVICE_NAME.yml)
      ---
      EOF"
      ;;
    *)
      echo "Serviço não encontrado! Use ./ci-cd.sh help para mais informações!"
      return 1
      ;;
  esac
	return 0
}         

# Parâmetros: <USERNAME> <ACCESS_TOKEN>
function login_dockerhub() {
  local USERNAME=$1
  local ACCESS_TOKEN=$2
  if ! docker login -u $USERNAME -p $ACCESS_TOKEN
    echo "Não foi possível logar no DockerHub! Confira suas credenciais de acesso!"
    return 4
  fi;  
  return 0
}

function create_tag_image() {
  TAG=head /dev/urandom | tc -dc 'a-z0-9'| fold -w 10 | head -n 1
}

# Parâmetros: <SERVICE_NAME> <USERNAME> <ACCESS_TOKEN> <REGISTRY_ADDRESS> <REGISTRY_NAME>
# <REACT_APP_BACKEND_URL> <REACT_APP_BACKEND_WS> <TAG>

function push_dockerhub() {
  local SERVICE_NAME=$1
  local USERNAME=$2
  local ACCESS_TOKEN=$3
  local REGISTRY_ADDRESS=$4
  local REGISTRY_NAME=$5
  local REACT_APP_BACKEND_URL=$6
  local REACT_APP_BACKEND_WS=$7
  local TAG=$8
  if ! login_dockerhub $USERNAME $PASSWORD
  then 
    return 4
  fi;
  case $SERVICE_NAME in 
		frontend)
      docker build -t $TAG --build-arg REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL REACT_APP_BACKEND_WS=$REACT_APP_BACKEND_WS $PWD/$SERVICE_NAME/ ./$SERVICE_NAME/
			docker tag $TAG $REGISTRY_ADDRESS/$REGISTRY_NAME:$TAG
			docker push $REGISTRY_ADDRESS/$REGISTRY_NAME:$TAG
			;;
		backend)
			docker build -t $TAG ./$SERVICE_NAME/
			docker tag $TAG $REGISTRY_ADDRESS/$REGISTRY_NAME:$TAG
			docker push $REGISTRY_ADDRESS/$REGISTRY_NAME:$TAG
			;;
		*)
			echo "Serviço não encontrado! Use ./ci-cd.sh help para mais informações!"
			return 1
			;;
	esac
	return 0
}

# Parâmetros: <SERVICE_NAME> <USERNAME> <ACCESS_TOKEN> <REGISTRY_ADDRESS> <REGISTRY_NAME> 
# <REACT_APP_BACKEND_URL> <REACT_APP_BACKEND_WS>
function pipeline() {
  local SERVICE_NAME=$1
  local USERNAME=$2
  local ACCESS_TOKEN=$3
  local REGISTRY_ADDRESS=$4
  local REGISTRY_NAME=$5
  local REACT_APP_BACKEND_URL=$6
  local REACT_APP_BACKEND_WS=$7
  create_tag_image
	case $SERVICE_NAME in
		frontend)
			test_service $SERVICE_NAME $REGISTRY_ADDRESS $REGISTRY_NAME $REACT_APP_BACKEND_URL $REACT_APP_BACKEND_WS $TAG
			push_dockerhub $SERVICE_NAME $USERNAME $ACCESS_TOKEN $REGISTRY_ADDRESS $REGISTRY_NAME $REACT_APP_BACKEND_URL $REACT_APP_BACKEND_WS $TAG
			deploy_service $SERVICE_NAME $REGISTRY_ADDRESS $REGISTRY_NAME $TAG
			;;
		backend)
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
			return -1
	esac
	return 0
}

# Script se inicia aqui!

if [[ $# -eq 1 && $1 == 'help' ]]; 
then
	echo "Este script contém diversas funcionalidades separadas sobre funções! Ele é capaz de
realizar o deploy do cluster Kubernetes localmente (Minikube), o processo de build, teste 
(em aplicações que contém testes), além do deploy de cada um dos serviços separado!
	
Uso: ./ci-cd.sh [COMMAND] <ARGS>

A lista de possíveis COMMAND estão descritas abaixo e o que cada um exemplo de uso:

test: Realiza os testes da aplicação em si, bem como a validação dos arquivos de definição do 
Kubernetes dentro das pastas de cada serviço!
Uso: ./ci-cd.sh test <frontend | backend | redis>  
		
pipeline: Este comando realiza o deploy de uma das aplicações!
Uso: ./ci-cd.sh pipeline <frontend | backend | redis>

ESTE SCRIPT ASSUME QUE SEU ARQUIVO DE CONFIGURAÇÃO DO MINIKUBE SE SITUA NO DIRETÓRIO PADRÃO: ~/.kube/config"
elif [[ $# -eq 2 && $1 == 'test' && ($2 == 'frontend' || $2 == 'backend'|| $2 == 'redis') ]];
then
	test_service $2
elif [[ $# -eq 2 && $1 == 'pipeline' && ($2 == 'frontend' || $2 == 'backend' || $2 == 'redis') ]];
then
	pipeline $2 $DOCKER_HUB_TOKEN_TESTE
else
	echo "Comando não encontrado!
Uso: ./ci-cd.sh [COMMAND]
Para mais informações sobre esse script, execute ./ci-cd.sh help"
fi;