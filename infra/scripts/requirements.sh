#!/bin/bash

# Este script instala todos os requisitos necessários para rodar o ambiente de aplicação

function update(){
  if ! (sudo apt update -y && sudo apt upgrade -y) then
    echo "Nao foi possivel realizar o update"
  fi;
  echo "Repositorios atualizados com sucesso"
}

function docker(){
  echo "Instalando pre requisitos"
    sudo apt install apt-transport-https -y
    sudo apt install ca-certificates -y
    sudo apt install curl -y
    sudo apt install gnupg-agent -y
    sudo apt install software-properties-common -y
  
  echo "Adicionando chave Docker"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    update
    sudo apt install docker-ce docker-ce-cli containerd.io -y
  
  echo "Permitindo o uso de Docker sem sudo"
    sudo usermod -aG docker ${USER}
  
  echo "Testando o uso de docker sem sudo"
    docker run hello-world

  echo "Done"
}

function kubernetes(){
  echo "Instalando o Kubectl."
    sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    sudo chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
  
  echo "Instalando o Minikube"
    sudo curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo chmod +x minikube
    sudo apt install minikube /usr/local/bin
  
  echo "Done"
}

update
docker
update
kubernetes
sudo apt autoremove -y
echo "Requisitos instalados com sucesso!"