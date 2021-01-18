#!/bin/bash 

# Este script é responsável por fazer toda a lógica de testes e deploy
# das aplicações no Minikube!

function test_service() {
	if [[ $2 == 'frontend']];
	then
		docker-compose build
		docker-compose up	
	elif [[ $2 == 'backend']];
	then
		echo "Verificando integridade dos arquivos Kubernetes!"
		if ! kubectl apply -f ./../../backend/k8s-$2.yml --validate=true --dry-run;
		then
			echo "Falha nas definições de Kubernetes do backend!"
			return -1
		fi;
	elif [[ $2 == 'redis']];
	then
		echo "Verificando integridade dos arquivos Kubernetes!"
		if ! kubectl apply -f ./../../database/redis/k8s-$2.yml --validate=true --dry-run ;
		then
			echo "Falha nas definições de Kubernetes do redis!"
			return -1
		fi; 
	else
		echo "Erro na execução do script! Consulte ./ci-cd.sh help para mais informações!"
		return -1
	fi;
	return 0
}

function deploy_service() {
	if [[ $2 == 'frontend']];
	then
		kubectl apply -f ./../../frontend/k8s-$2.yml
	elif [[ $2 == 'backend']];
	then
		kubectl apply -f ./../../backend/k8s-$2.yml
	elif [[ $t2 == 'redis']];
	then
		kubectl apply -f ./../../database/redis/k8s-$2.yml
	else
		echo "Erro na execução do script! Consulte ./ci-cd.sh help para mais informações!"
		return -1
	fi;
	return 0
}         

function deploy_stack() {
	echo "Deploy da stack seguindo ordem de dependência!"
		kubectl apply -f ./../../database/redis/k8s-redis.yml
		kubectl apply -f ./../../backend/k8s-backend.yml
		kubectl apply -f ./../../frontend/k8s-frontend.yml
	return 0
}

# Script se inicia aqui!

if [[ $# -eq 1 && $1 == 'help' ]];
then
	echo "Este script contém diversas funcionalidades separadas sobre funções! Ele é capaz de
	realizar o deploy do cluster Kubernetes localmente (Minikube), o processo de build, teste 
	(em aplicações que contém testes), além do deploy parcial ou total do sistema!
	
	Uso: ./ci-cd.sh [COMMAND] <ARGS>

	A lista de possíveis COMMAND estão descritas abaixo e o que cada um exemplo de uso:

	environment: Realiza o deploy completo do ambiente de infraestrutura!
		Uso: ./ci-cd.sh environment

	test: Realiza os testes da aplicação em si, bem como a validação dos arquivos de definição do 
	Kubernetes dentro das pastas de cada serviço!
		Uso: ./ci-cd.sh test <frontend | backend | redis>  

	deploy: Este comando realiza o deploy do sistema completo, podendo ser parcial ou total!

		Uso: ./ci-cd.sh deploy <service | all> <service_name>
			
			Para o caso do deploy ser feito de um serviço (service), o usuário deverá especificar qual serviço
			ele quer que o deploy seja realizado, logo em seguida como um parâmetro, seguindo a lista de
			possíveis parâmetros estipulados no comando test!

			A lista de possíveis services (<service_name>) são:
				backend
				frontend
				redis
		
			Para o caso do deploy ser total (all), todos os serviços passam a ser deployados dentro do cluster!
			
	ESTE SCRIPT ASSUME QUE SEU ARQUIVO DE CONFIGURAÇÃO DO MINIKUBE SE SITUA NO DIRETÓRIO PADRÃO: ~/.kube/config
	"
	
elif [[ $# -eq 2 && $1 == 'test' && ($2 == 'frontend' || $2 == 'backend'|| $2 == 'redis')]];
then
	test_service
elif [[ $# -eq 2 && $1 == 'deploy' && $2 == 'all']];
then
	deploy_stack
elif [[ $# -eq 3 && $1 == 'deploy' && $2 == 'service' && ($3 == 'frontend' || $3 == 'backend' || $3 == 'redis')]];
then
	deploy_service
else
	" Comando não encontrado!
	
		Uso: ./ci-cd.sh [COMMAND]
	
		Para mais informações sobre esse script, execute ./ci-cd.sh help
	"
fi;