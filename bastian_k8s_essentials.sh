#!/bin/bash

log(){
    echo "`date -u` : $0 :: $1" >> $0_logfile.log
}

permissions() {
    if [[ "$EUID" -ne 0 ]] ; then
        echo 'run script with SUDO permissions' && log 'run script with SUDO permissions'
        exit 1
    fi
}

apt_upgrade() {
    log "running apt update"
    apt update -y >> $0_logfile.log && log "apt update completed" || { log "apt update failed"; exit 1; }
    log "running apt upgrade"
    apt upgrade -y >> $0_logfile.log && log "apt upgrade completed" || { log "apt upgrade failed"; exit 1; }
}

dep_install() {
    log "installing dependencies"
    apt install curl -y >> $0_logfile.log && log "curl installed" || { log "curl installation failed"; exit 1; }
}

aws_cli() {
    log "running apt install for aws cli"
    apt-get install awscli -y  >> $0_logfile.log && log "apt install completed for aws cli" || { log "apt install failed for aws cli"; exit 1; }
    aws --version >> $0_logfile.log && log "aws cli validation completed" || { log "aws cli validation failed"; exit 1; }
}

eks_ctl() {
    log "installing eksctl"
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp  >> $0_logfile.log && log "downloaded eksctl binary" || { log "eksctl binary download failed"; exit 1; }
    rm -rf eksctl_$(uname -s)_amd64.tar.gz >> $0_logfile.log && log "removed eksctl zip" || { log "failed to remove eksctl zip"; exit 1; }
    mv /tmp/eksctl /usr/local/bin >> $0_logfile.log && log "configured eksctl binary in /usr/local/bin" || { log "failed to configure eksctl binary in /usr/local/bin"; exit 1; }
    eksctl version >> $0_logfile.log && log "eksctl validation completed" || { log "eksctl validation failed"; exit 1; }
}

kube_ctl() {
    log "installing kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"  >> $0_logfile.log && log "downloaded eksctl binary" || { log "eksctl binary download failed"; exit 1; }
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl >> $0_logfile.log && log "configured kubectl binary in /usr/local/bin" || { log "failed to configure kubectl binary in /usr/local/bin"; exit 1; }
    rm -rf kubectl >> $0_logfile.log && log "removed kubectl zip" || { log "failed to remove kubectl zip"; exit 1; }
    kubectl version --client  --output=yaml >> $0_logfile.log && log "kubectl validation completed" || { log "kubectl validation failed"; exit 1; }
}

helm_install() {
    log "installing helm"
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null && log "configured keyring for helm install" || { log "failed to configured keyring for helm install"; exit 1; }
    apt-get install apt-transport-https --yes >> $0_logfile.log && log "apt install completed for apt-transport-https" || { log "apt install failed for apt-transport-https"; exit 1; }
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list && log "added helm repo in apt repo list" || { log "failed to add helm repo in apt repo list"; exit 1; }
    apt update -y >> $0_logfile.log && log "apt update completed after adding helm repo" || { log "apt update failed after adding helm repo"; exit 1; }
    apt-get install helm -y  >> $0_logfile.log && log "apt install completed for helm" || { log "apt install failed for helm"; exit 1; }
    helm version >> $0_logfile.log && log "helm validation completed" || { log "helm validation failed"; exit 1; }
}

nfs_tools() {
    log "installing nfs tools"
    apt-get install nfs-common -y >> $0_logfile.log && log "apt install completed for nfs tools" || { log "apt install failed for nfs tools"; exit 1; }
}

run_script() {
    permissions
    apt_upgrade

    curl --version > /dev/null && log "curl already installed, skipping" || dep_install
    aws --version > /dev/null && log "aws cli already installed, skipping" || aws_cli
    eksctl version > /dev/null && log "eksctl already installed, skipping" || eks_ctl
    kubectl version --client > /dev/null && log "kubectl already installed, skipping" || kube_ctl
    helm version > /dev/null && log "aws cli already installed, skipping" || helm_install
    nfs_tools

    exit
}

run_script