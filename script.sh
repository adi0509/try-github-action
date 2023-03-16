#!/usr/bin/env bash

install_required_stuff () {
    #check docker
    if [ ! -x "$(command -v docker)" ]; then
        echo "\n-------------Installing docker-------------\n"
        sudo apt-get update
        sudo apt-get install \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
        sudo mkdir -m 0755 -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl enable docker
        echo "\n-------------------------------------------\n"
    else
        echo "\n-------------Docker already installed-------------\n"
    fi

    #check kubectl
    if [ ! -x "$(command -v kubectl)" ]; then
        echo "\n-------------Installing kubectl-------------\n"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        echo "\n-------------------------------------------\n"
    else
        echo "\n-------------kubectl already installed-------------\n"
    fi

    #check kind
    if [ ! -x "$(command -v kind)" ]; then
        echo "\n-------------Installing kind-------------\n"
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
        echo "\n-------------------------------------------\n"
    else
        echo "\n-------------Kind already installed-------------\n"
    fi
}

create_cluster () {
    echo "\n-------------Creating kind cluster-------------\n"
    kind create cluster --config=./k8s-setup/kind-config.yaml
    echo "\n-------------port-forwarding k8s API server-------------"
    kubectl proxy --port=8000 --address 0.0.0.0 --accept-hosts '.*' &
    echo "\n-------------------------------------------\n"
}

setup_cluster () {
    kubectl create serviceaccount github-actions
    kubectl apply -f ./k8s-setup/clusterrole.yaml
    kubectl create clusterrolebinding continuous-deployment \
        --clusterrole=continuous-deployment --serviceaccount=default:github-actions
    # kubectl create token github-actions --duration=99999h
    kubectl create -f ./k8s-setup/secret.yaml
    echo "\n\n-------------COPY THIS OUTPUT-------------\n"
    kubectl  get secrets github-action-token -o yaml
}
