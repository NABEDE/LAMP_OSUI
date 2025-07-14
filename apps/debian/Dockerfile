FROM debian:bookworm

LABEL maintainer="NABEDE"

ENV DEBIAN_FRONTEND=noninteractive

# Installation des outils nécessaires pour le script
RUN apt-get update && \
    apt-get install -y sudo wget curl vim net-tools iputils-ping lsb-release gnupg && \
    apt-get clean && rm -rf /var/lib/apt/lists/* \
    apt-get install systemd systemd-sysv

# Copie du script d'installation LAMP
COPY apps/debian/install.sh /install.sh
RUN chmod +x /install.sh

# Expose le port 80 pour Apache
EXPOSE 80

# Lance install.sh automatiquement (sans confirmation)
ENTRYPOINT ["/install.sh", "--no-confirm"]