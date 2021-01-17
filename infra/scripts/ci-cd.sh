#!/bin/bash 

# Este script é responsável por fazer toda a lógica do CI e até mesmo CD
# das aplicações que compõem esse sistema!

function deploy_environment() {
  return 0
}

function test_service() {
	return 0
}

function deploy_service() {
	return 0
}         

function deploy_stack() {
	return 0
}

function push_docker_image_service() {
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
	
elif [[ $# -eq 1 && $1 == 'environment' ]];
then

elif [[ $# -eq 2 && $1 == 'test' && $2 == 'frontend']];
then

elif [[ $# -eq 2 && $1 == 'test' && $2 == 'backend']];
then

elif [[ $# -eq 2 && $1 == 'test' && $2 == 'redis']];
then

elif [[ $# -eq 2 && $1 == 'deploy' && $2 == 'all']];
then

elif [[ $# -eq 3 && $1 == 'deploy' && $2 == 'service' && $3 == 'frontend']];
then

elif [[ $# -eq 3 && $1 == 'deploy' && $2 == 'service' && $3 == 'backend']];
then

elif [[ $# -eq 3 && $1 == 'deploy' && $2 == 'service' && $3 == 'redis']];
then

else

	" Comando não encontrado!
	
		Uso: ./ci-cd.sh [COMMAND]
	
		Para mais informações sobre esse script, execute ./ci-cd.sh help
	"
fi;