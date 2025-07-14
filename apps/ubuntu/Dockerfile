FROM ubuntu:noble

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y gnupg curl vim net-tools iputils-ping sudo \
    apt-get install -y systemd systemd-sysv

# Copie le script principal et le logo dans des emplacements accessibles
COPY apps/ubuntu/install.sh /install.sh
COPY apps/logo.sh /logo.sh

RUN chmod +x /install.sh /logo.sh

# (Option) Désactive sudo : dans un conteneur tu es root
RUN sed -i 's/sudo //g' /install.sh

# Pour permettre le fonctionnement de systemctl/service dans Docker, 
# il est conseillé d’utiliser --privileged à l’exécution

EXPOSE 80

CMD ["/bin/bash", "/install.sh", "--no-confirm"]