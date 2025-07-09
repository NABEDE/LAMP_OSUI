FROM debian:trixie-backports

# Installer les utilitaires nécessaires et systemd
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y sudo wget curl vim net-tools rsyslog systemctl iputils-ping && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copier le script d'installation LAMP
COPY apps/debian/install.sh /install.sh
RUN chmod +x /install.sh

# Pour permettre le lancement de systemd (nécessaire pour systemctl)
STOPSIGNAL SIGRTMIN+3
ENV container docker

# Lancer le script d'installation automatiquement (sans confirmation)
ENTRYPOINT ["/install.sh", "--no-confirm"]

EXPOSE 80