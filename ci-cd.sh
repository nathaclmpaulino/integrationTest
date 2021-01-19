#!/bin/bash 

# Este script é responsável por fazer toda a lógica de testes e deploy
# das aplicações no Minikube!
# 
# Caso queira saber como ele funciona, use o comando ./ci-cd.sh help

function test_service() {
	if [[ $1 == 'frontend' ]];
	then
		if ! docker build --build-arg REACT_APP_BACKEND_WS=http://backend.cluster --build-arg REACT_APP_BACKEND_URL=http://backend.cluster -f $PWD/frontend/Dockerfile.test;
		then
			echo "Falha no teste do container do $1!"
			return -3
		elif ! kubectl apply -f $PWD/frontend/kubernetes/k8s-$1.yml --validate=true --dry-run=client || kubectl apply -f $PWD/frontend/kubernetes/k8s-$1-ingress.yml --validate=true --dry-run=client;
		then
			echo "Erro na validação dos arquivos de definição de K8s do $1!"
			return -2
		fi;
	elif [[ $1 == 'backend' ]];
	then
		if ! kubectl apply -f $PWD/backend/kubernetes/k8s-$1.yml --validate=true --dry-run=client || kubectl apply -f $PWD/frontend/kubernetes/k8s-$1-ingress.yml --validate=true --dry-run=client || kubectl apply -f $PWD/frontend/kubernetesk8s-$1-config.yml --validate=true --dry-run=client;
		then
			echo "Erro na validação dos arquivos de definição de K8s do $1!"
			return -2
		fi;
	elif [[ $1 == 'redis' ]];
	then
		if ! kubectl apply -f $PWD/database/redis/k8s-$1.yml --validate=true --dry-run=client ;
		then
			echo "Erro na validação dos arquivos de definição de K8s do $1!"
			return -2
		fi; 
	else
		echo "Erro na execução do script! Consulte ./ci-cd.sh help para mais informações!"
		return -1
	fi;
	return 0
}

function deploy_service() {
	if [[ $1 == 'frontend' ]];
	then
		kubectl apply -f $PWD/frontend/kubernetes/k8s-$1-ingress.yml
		kubectl apply -f $PWD/frontend/kubernetes/k8s-$1.yml
	elif [[ $1 == 'backend' ]];
	then
		kubectl apply -f $PWD/backend/kubernetes/k8s-$1-config.yml
		kubectl apply -f $PWD/backend/kubernetes/k8s-$1-ingress.yml
		kubectl apply -f $PWD/backend/kubernetes/k8s-$1.yml
	elif [[ $1 == 'redis' ]];
	then
		kubectl apply -f $PWD/database/redis/k8s-$1.yml
	else
		echo "Erro na execução do script! Consulte ./ci-cd.sh help para mais informações!"
		return -1
	fi;
	return 0
}         

function push_dockerhub() {
	case $1 in 
		frontend)
			docker build -t frontend --build-arg REACT_APP_BACKEND_URL=http://backend.cluster REACT_APP_BACKEND_WS=http://backend.cluster $PWD/frontend
			docker tag frontend nathapaulino/frontend-chatapp
			docker push nathapaulino/frontend-chatapp
			;;
		backend)
			docker build -t backend $PWD/backend
			docker tag backend nathapaulino/backend-chatapp
			docker push nathapaulino/backend-chatapp
			;;
		*)
			echo "Serviço não encontrado!"
			return -1
			;;
	esac
	return 0
}

function pipeline() {
	case $1 in
		frontend)
			test_service $1
			push_dockerhub $1
			deploy_service $1
			;;
		backend)
			test_service $1
			push_dockerhub $1
			deploy_service $1
			;;
		redis)
			test_service $1
			deploy_service $1
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
	pipeline $2
else
	echo "Comando não encontrado!
Uso: ./ci-cd.sh [COMMAND]
Para mais informações sobre esse script, execute ./ci-cd.sh help"
fi;