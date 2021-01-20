#!/bin/bash

function update(){
  if ! (sudo apt-get update -y > /dev/null && sudo apt-get upgrade -y > /dev/null) then
    echo "Nao foi possivel realizar o update"
  fi;
  echo "Repositorios atualizados com sucesso"
}

function install_docker(){
  echo "Instalando pre requisitos"
    sudo apt-get install apt-transport-https -y > /dev/null
    sudo apt-get install ca-certificates -y > /dev/null
    sudo apt-get install curl -y > /dev/null
    sudo apt-get install gnupg-agent -y > /dev/null
    sudo apt-get install software-properties-common -y > /dev/null
  
  echo "Adicionando chave Docker"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /dev/null
    update
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null
  
  echo "Permitindo o uso de Docker sem sudo"
    sudo usermod -aG docker ${USER}

  return 0
}

function install_kubernetes(){
  echo "Instalando o Kubectl."
    sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl > /dev/null
    sudo chmod +x ./kubectl > /dev/null
    sudo mv ./kubectl /usr/local/bin/kubectl > /dev/null
  
  echo "Instalando o Minikube"
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
  
  return 0
}

function run_minikube(){
  minikube start
  minikube addons enable storage-provisioner 
  minikube addons enable ingress
  minikube ip
  return 0
}

if [[ $# -eq 1 ]]; 
then
  case $1 in
    help)
        echo "Uso: ./requirements.sh [COMMAND]"
        echo "Lista de COMMAND disponíveis:
              help: Mostra uma ajuda!
              docker: Instala o docker na máquina!
              k8s: Instala o minikube e o kubectl na máquina!
              run: Instala as dependências todas do projeto!
              config: Roda o ambiente local do Minikube! Este comando deve ser rodado apenas depois de instalar o docker e o minikube!"
        echo "Este script instala os requisitos para rodar esse repositório! (Docker, Kubernetes, Minikube)"    
      ;;
    k8s)
      update
      install_kubernetes
      ;;
    docker)
      update
      install_docker
      ;;
    run)
      update 
      install_docker
      update
      install_kubernetes
      ;;
    config)
      run_minikube
      ;;
  esac
else
  echo "Use ./requirements.sh help para mais informações!"
fi;