# Utiliser l’image officielle CentOS (ou Rocky Linux pour un équivalent moderne)
FROM centos:8

# Empêcher les interactions pendant l'installation (utile pour les scripts non interactifs)
ENV DEBIAN_FRONTEND=noninteractive

# Installer sudo et utilitaires de base
RUN yum -y update && \
    yum -y install sudo curl which iputils

# Créer un utilisateur non-root pour les tests si besoin (optionnel)
# RUN useradd -m testuser && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copier ton script d'installation et le rendre exécutable
COPY apps/centos/install.sh /install.sh
COPY apps/logo.sh /logo.sh

RUN chmod +x /install.sh /logo.sh

# Lancer le script à la création du conteneur
CMD ["/install.sh", "--no-confirm"]