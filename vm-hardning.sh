#!/bin/bash

permissions() {
    if [[ "$EUID" -ne 0 ]] ; then
        echo 'run script with SUDO permissions'
        exit 1
    fi
}

apt_upgrade() {
    echo "running apt update"
    apt update -y && echo "apt update completed" || { echo "apt update failed"; exit 1; }
    apt upgrade -y && echo "apt upgrade completed" || { echo "apt upgrade failed"; exit 1; }
}

install_sysstat() {
    echo "installing sysstat"
    apt install -y sysstat && echo "sysstat install completed" || { echo "sysstat install failed"; exit 1; }
    sed -i 's/ENABLED="false"/ENABLED="true"/g' /etc/default/sysstat && echo "updated sysstat conf" || { echo "sysstat conf update failed"; exit 1; }
    sed -i 's/5-55\/10/*\/1/g' /etc/cron.d/sysstat && echo "updated sysstat cron" || { echo "sysstat cron update failed"; exit 1; }
}

set_security_limits() {
    echo "setting security limits"
    echo "* soft nproc 100000" >> /etc/security/limits.conf && echo "* soft nproc set" || { echo "* soft nproc set failed"; exit 1; }
    echo "* hard nproc 100000" >> /etc/security/limits.conf && echo "* hard nproc set" || { echo "* hard nproc set failed"; exit 1; }
    echo "* soft nofile 100000" >> /etc/security/limits.conf && echo "* soft nofile set" || { echo "* soft nofile set failed"; exit 1; }
    echo "* hard nofile 100000" >> /etc/security/limits.conf && echo "* hard nofile set" || { echo "* hard nofile set failed"; exit 1; }
    echo "root soft nproc 100000" >> /etc/security/limits.conf && echo "root soft nproc set" || { echo "root soft nproc set failed"; exit 1; }
    echo "root hard nproc 100000" >> /etc/security/limits.conf && echo "root hard nproc set" || { echo "root hard nproc set failed"; exit 1; }
    echo "root soft nofile 100000" >> /etc/security/limits.conf && echo "root soft nofile set" || { echo "root soft nofile set failed"; exit 1; }
    echo "root hard nofile 100000" >> /etc/security/limits.conf && echo "root hard nofile set" || { echo "root hard nofile set failed"; exit 1; }
}

set_systemd_user() {
    echo "setting systemd user conf"
    echo "DefaultLimitNOFILE=100000" >> /etc/systemd/user.conf && echo "systemd user set" || { echo "systemd user set failed"; exit 1; }   
}

set_systemd_system() {
    echo "setting systemd system conf"
    echo "DefaultLimitNOFILE=100000" >> /etc/systemd/system.conf && echo "systemd system set" || { echo "systemd system set failed"; exit 1; }   
}

set_sysctl_conf() {
    echo "setting sysctl conf"
    echo "fs.file-max = 65536" >> /etc/sysctl.conf && echo "sysctl file-max set" || { echo "sysctl file-max set failed"; exit 1; }   
    echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf && echo "sysctl overcommit_memory set" || { echo "sysctl overcommit_memory set failed"; exit 1; }   
    echo "net.ipv4.tcp_max_syn_backlog = 4096" >> /etc/sysctl.conf && echo "sysctl tcp_max_syn_backlog set" || { echo "sysctl tcp_max_syn_backlog set failed"; exit 1; }   
    echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf && echo "sysctl tcp_fin_timeout set" || { echo "sysctl tcp_fin_timeout set failed"; exit 1; }   
    echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf && echo "sysctl tcp_tw_recycle set" || { echo "sysctl tcp_tw_recycle set failed"; exit 1; }   
    echo "vm.swappiness = 10" >> /etc/sysctl.conf && echo "sysctl swappiness set" || { echo "sysctl swappiness set failed"; exit 1; }   
}

install_ntp() {
    echo "installing ntp"
    apt update -y && echo "apt update completed" || { echo "apt update failed"; exit 1; }
    apt install ntp -y && echo "ntp install completed" || { echo "ntp install failed"; exit 1; }
    service ntp stop && echo "ntp service stopped successfully" || { echo "ntp service stop failed"; exit 1; }
    ntpd -gq && echo "ntp check passed successfully" || { echo "ntp check failed, set nameserver in /etc/resolv.conf"; exit 1; }
    service ntp start && echo "ntp service started successfully" || { echo "ntp service start failed"; exit 1; }
}

set_profile() {
    echo "setting profile"
    echo 'export HISTTIMEFORMAT="%F %T "' >> /etc/profile && echo "added entry in profile" || { echo "entry on profile failed"; exit 1; }
    source /etc/profile && echo "profile source done" || { echo "profile source failed"; exit 1; }
}

set_bashrc() {
    echo "setting bashrc"
    echo "PROMPT_COMMAND='history -a >(tee -a ~/.bash_history | logger -p local6.info -t "$USER[$$] $SSH_CONNECTION")'" >> /etc/bash.bashrc && echo "added entry in bashrc" || { echo "entry on bashrc failed"; exit 1; }
    source /etc/bash.bashrc && echo "bashrc source done" || { echo "bashrc source failed"; exit 1; }
}

set_rsyslog() {
    echo "setting rsyslog"
    echo "local6.info /var/log/history.log" >> /etc/rsyslog.d/50-default.conf && echo "added entry in rsyslog" || { echo "entry on rsyslog failed"; exit 1; }
    touch /var/log/history.log && echo "added history log file" || { echo "failed to add history log file"; exit 1; }
    chmod -R 777 /var/log/history.log && echo "permissions added to log file" || { echo "failed to add permissions to log file"; exit 1; }
    chown -R syslog:adm /var/log/history.log && echo "ownership set to log file" || { echo "setting ownership of log file failed"; exit 1; }
    /etc/init.d/rsyslog restart && echo "rsyslog service restarted successfully" || { echo "rsyslog service restart failed"; exit 1; }
}

run_script() {
    permissions
    apt_upgrade
    install_sysstat
    set_security_limits
    set_systemd_user
    set_systemd_system
    set_sysctl_conf
    install_ntp
    set_profile
    set_bashrc
    set_rsyslog

    exit
}

run_script
