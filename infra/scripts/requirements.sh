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
    source ~/.bashrc

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

function check_versions(){
  echo "Teste de versão do docker!"
    docker --version

  echo "Teste de versão do Minikube!"
    minikube version

  echo "Teste de versão do Kubectl!"
    kubectl version --client
  
  return 0
}

if [[ $# -eq 1 && $1 == 'help' ]]; 
then
  echo "Uso: ./requirements.sh"
  echo "Este script instala os requisitos para rodar esse repositório! (Docker, Kubernetes, Minikube)"
elif [[ $# -gt 1 ]]; 
then
  echo "Uso: ./requirements.sh"
  echo "Para mais informações use: ./requirements.sh help"
else
  update
  install_docker
  update
  install_kubernetes
  check_versions
  echo "Requisitos instalados com sucesso!"
fi;