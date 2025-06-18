#!/bin/bash

# ==============================================================================
# Script d'Installation LAMP Perfectionné pour CentOS
# Ce script installe et configure un environnement LAMP (Linux, Apache, MySQL, PHP)
# sur les systèmes basés sur CentOS.
#
# Auteur: Votre Nom / Modifié par Gemini
# Date: 12 Juin 2025
# ==============================================================================

# --- Variables de configuration ---
# Vous pouvez modifier ces variables si nécessaire
PHP_VERSION="8.1" # Exemple: "7.4", "8.1", etc. (doit être disponible dans les dépôts)
# Note: Pour PHP 8.x sur CentOS, vous devrez probablement activer les dépôts EPEL et Remi.
# Le script tentera de le faire automatiquement.
PHP_MODULES=(
    "php"
    "php-mysqlnd" # mysqlnd est le pilote recommandé pour PHP 7+
    "php-cli"
    "php-json"
    "php-gd"
    "php-curl"
    "php-mbstring"
    "php-xml"
    "php-zip"
    "php-intl"
    "php-soap"
)
WEB_ROOT="/var/www/html"
LOG_FILE="lamp_install_$(date +%Y%m%d_%H%M%S).log" # Fichier de log avec horodatage

# --- Codes de couleur ANSI ---
RED='\e[1;31m'    # Rouge gras
GREEN='\e[1;32m'  # Vert gras
YELLOW='\e[1;33m' # Jaune gras
BLUE='\e[1;34m'   # Bleu gras
NC='\e[0m'        # Pas de couleur (Reset)

# --- Fonctions d'affichage ---
function error_exit {
    echo -e "${RED}ERREUR: $1${NC}" | tee -a "$LOG_FILE" >&2 # Affiche l'erreur en rouge gras et log
    exit 1
}

function info_msg {
    echo -e "${BLUE}$1${NC}" | tee -a "$LOG_FILE" # Affiche l'information en bleu gras et log
}

function success_msg {
    echo -e "${GREEN}$1${NC}" | tee -a "$LOG_FILE" # Affiche le succès en vert gras et log
}

function warn_msg {
    echo -e "${YELLOW}AVERTISSEMENT: $1${NC}" | tee -a "$LOG_FILE" # Affiche l'avertissement en jaune gras et log
}

# --- Fonction d'aide ---
function show_help {
    echo -e "${BLUE}Utilisation: sudo ./install_lamp_centos.sh [options]${NC}"
    echo -e "${BLUE}Ce script installe un environnement LAMP (Linux, Apache, MySQL, PHP) sur CentOS.${NC}"
    echo -e "${BLUE}Options disponibles:${NC}"
    echo -e "  ${GREEN}--help${NC}    Affiche ce message d'aide."
    echo -e "  ${GREEN}--no-confirm${NC}  Exécute le script sans demander de confirmation."
    echo -e "\n${YELLOW}Assurez-vous d'avoir une connexion internet active.${NC}"
    exit 0
}

# --- Traitement des arguments de ligne de commande ---
NO_CONFIRM=false
for arg in "$@"; do
    case "$arg" in
        --help)
            show_help
            ;;
        --no-confirm)
            NO_CONFIRM=true
            ;;
        *)
            warn_msg "Option inconnue: $arg"
            show_help
            ;;
    esac
done

# --- Logo LAMP en ASCII art ---
info_msg "
  ${YELLOW}**** **** **** ****${NC}
 ${YELLOW}* ${BLUE}L${YELLOW} * ${BLUE}A${YELLOW} * ${BLUE}M${YELLOW} * ${BLUE}P${YELLOW} *${NC}
${YELLOW}* * * * * * * *${NC}
${YELLOW}* ${BLUE}** ${YELLOW}** * ${RED}****${NC}
 ${YELLOW}* * * * * * *${NC}
  ${YELLOW}* * * * * *${NC}
   ${YELLOW}**** **** **** ****${NC}
"
info_msg "--- Script d'Installation LAMP Perfectionné pour CentOS ---"
info_msg "La sortie de ce script sera également enregistrée dans: ${LOG_FILE}"
info_msg "---"

# --- Pré-vérifications ---
# Vérifier si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   error_exit "Ce script doit être exécuté en tant que root. Utilisez 'sudo ./install_lamp_centos.sh'."
fi

# Détecter le gestionnaire de paquets (dnf ou yum)
if command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    info_msg "Utilisation de DNF comme gestionnaire de paquets."
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    info_msg "Utilisation de YUM comme gestionnaire de paquets."
else
    error_exit "Aucun gestionnaire de paquets (dnf ou yum) trouvé. Ce script est conçu pour CentOS/RHEL."
fi

# Test de connexion à internet
info_msg "Vérification de la connexion internet..."
if ! ping -c 1 google.com &> /dev/null; then
    error_exit "Impossible de se connecter à Internet. Veuillez vérifier votre connexion et réessayer."
else
    info_msg "Connexion Internet OK"
fi

# Vérifier la distribution (prend en charge CentOS/RHEL)
if ! grep -q "CentOS" /etc/redhat-release && ! grep -q "Red Hat Enterprise Linux" /etc/redhat-release; then
    error_exit "Ce script est conçu pour les systèmes basés sur CentOS/RHEL. Votre système ne semble pas l'être."
fi

# Demander confirmation avant de commencer si --no-confirm n'est pas utilisé
if ! $NO_CONFIRM; then
    read -p "$(info_msg "Voulez-vous démarrer l'installation LAMP sur CentOS ? (O/n) ")" confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        info_msg "Installation annulée par l'utilisateur."
        exit 0
    fi
fi

info_msg "Démarrage de l'installation..."
info_msg "---"

# --- Étape 1: Mise à jour des paquets système ---
info_msg "Mise à jour des paquets système..."
if sudo $PKG_MANAGER -y update; then
    success_msg "Mise à jour des paquets réussie."
else
    error_exit "Échec de la mise à jour des paquets. Vérifiez votre connexion internet ou les dépôts."
fi

# --- Étape 2: Installation et configuration d'Apache (httpd) ---
info_msg "---"
info_msg "Installation et configuration d'Apache (httpd)..."
if sudo $PKG_MANAGER -y install httpd; then
    success_msg "Apache (httpd) installé avec succès."
else
    error_exit "Échec de l'installation d'Apache (httpd). Le script s'arrête."
fi

if sudo systemctl enable httpd; then
    success_msg "Apache (httpd) activé pour démarrer au démarrage du système."
else
    warn_msg "Échec de l'activation d'Apache (httpd) au démarrage. Veuillez vérifier manuellement."
fi

if sudo systemctl start httpd; then
    success_msg "Apache (httpd) démarré avec succès."
else
    error_exit "Échec du démarrage d'Apache (httpd). Vérifiez les logs Apache pour plus de détails. Le script s'arrête."
    warn_msg "Affichage des logs Apache pour le débogage:"
    journalctl -xeu httpd.service | tee -a "$LOG_FILE" # Affiche et log les logs Apache
    error_exit "Échec du démarrage d'Apache (httpd). Vérifiez les logs Apache ci-dessus pour plus de détails. Le script s'arrête."
fi

# Configuration du pare-feu pour Apache
info_msg "Configuration du pare-feu pour Apache..."
if sudo firewall-cmd --permanent --add-service=http && sudo firewall-cmd --permanent --add-service=https && sudo firewall-cmd --reload; then
    success_msg "Services HTTP et HTTPS ajoutés au pare-feu et pare-feu rechargé."
else
    warn_msg "Échec de la configuration du pare-feu. Veuillez vérifier manuellement (firewall-cmd)."
fi

# --- Étape 3: Installation et configuration de MySQL Server (MariaDB) ---
info_msg "---"
info_msg "Installation et configuration de MySQL Server (MariaDB par défaut sur CentOS)..."
if sudo $PKG_MANAGER -y install mariadb-server mariadb; then
    success_msg "MariaDB Server installé avec succès."
else
    error_exit "Échec de l'installation de MariaDB Server. Le script s'arrête."
    warn_msg "Affichage des logs MariaDB pour le débogage:"
    journalctl -xeu mariadb.service | tee -a "$LOG_FILE" # Affiche et log les logs MariaDB
    error_exit "Échec de l'installation de MariaDB Server. Vérifiez les logs MariaDB ci-dessus pour plus de détails. Le script s'arrête."
fi

if sudo systemctl enable mariadb; then
    success_msg "MariaDB activé pour démarrer au démarrage du système."
else
    warn_msg "Échec de l'activation de MariaDB au démarrage. Veuillez vérifier manuellement."
    warn_msg "Affichage des logs MariaDB pour le débogage:"
    journalctl -xeu mariadb.service | tee -a "$LOG_FILE" # Affiche et log les logs MariaDB
fi

if sudo systemctl start mariadb; then
    success_msg "MariaDB démarré avec succès."
else
    error_exit "Échec du démarrage de MariaDB. Vérifiez les logs MariaDB pour plus de détails. Le script s'arrête."
    warn_msg "Affichage des logs MariaDB pour le débogage:"
    journalctl -xeu mariadb.service | tee -a "$LOG_FILE" # Affiche et log les logs MariaDB
    error_exit "Échec du démarrage de MariaDB. Vérifiez les logs MariaDB ci-dessus pour plus de détails. Le script s'arrête."
fi

info_msg "---"
info_msg "Sécurisation de l'installation de MariaDB..."
info_msg "Veuillez suivre attentivement les instructions qui vont apparaître pour définir un mot de passe ROOT pour MariaDB et sécuriser votre installation."
if sudo mysql_secure_installation; then
    success_msg "Sécurisation de MariaDB terminée avec succès."
else
    warn_msg "La sécurisation de MariaDB n'a pas été complétée ou a rencontré des erreurs. Veuillez la faire manuellement plus tard (sudo mysql_secure_installation)."
fi

# --- Étape 4: Installation et configuration de PHP ---
info_msg "---"
info_msg "Installation de PHP ${PHP_VERSION} et des modules courants..."

# Activation des dépôts EPEL et Remi pour PHP
info_msg "Activation des dépôts EPEL et Remi pour un accès facilité aux versions récentes de PHP..."
if sudo $PKG_MANAGER -y install epel-release; then
    success_msg "Dépôt EPEL activé."
else
    warn_msg "Échec de l'activation du dépôt EPEL. Vous pourriez rencontrer des problèmes avec l'installation de PHP."
fi

if sudo $PKG_MANAGER -y install https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm; then
    success_msg "Dépôt Remi activé."
else
    warn_msg "Échec de l'activation du dépôt Remi. Vous pourriez rencontrer des problèmes avec l'installation de PHP."
fi

# Activer la version spécifique de PHP dans le dépôt Remi
if sudo $PKG_MANAGER module -y reset php && sudo $PKG_MANAGER module -y enable php:remi-${PHP_VERSION//./}; then
    success_msg "Module PHP version ${PHP_VERSION} activé depuis le dépôt Remi."
else
    error_exit "Échec de l'activation du module PHP ${PHP_VERSION} depuis le dépôt Remi. Vérifiez si la version est correcte ou si les dépôts sont bien configurés. Le script s'arrête."
fi

# Construire la liste des modules PHP
PHP_INSTALL_COMMAND=""
for module in "${PHP_MODULES[@]}"; do
    PHP_INSTALL_COMMAND+="$module "
done

if sudo $PKG_MANAGER -y install $PHP_INSTALL_COMMAND; then
    success_msg "PHP ${PHP_VERSION} et ses modules installés avec succès."
else
    error_exit "Échec de l'installation de PHP ou de certains modules. Vérifiez si la version PHP ${PHP_VERSION} est disponible dans les dépôts Remi. Le script s'arrête."
fi

info_msg "---"
info_msg "Redémarrage d'Apache (httpd) pour appliquer les changements PHP..."
if sudo systemctl restart httpd; then
    success_msg "Apache (httpd) redémarré avec succès."
else
    error_exit "Échec du redémarrage d'Apache (httpd). Le script s'arrête."
fi

# --- Étape 5: Vérifications finales ---
info_msg "---"
info_msg "Vérification des versions installées:"
httpd -v | head -n 1 | tee -a "$LOG_FILE"
mysql --version | tee -a "$LOG_FILE" # MariaDB utilise la commande mysql
php -v | head -n 1 | tee -a "$LOG_FILE"

info_msg "---"
info_msg "Vérification de l'état des services:"
if systemctl is-active --quiet httpd && systemctl is-active --quiet mariadb; then
    success_msg "Apache (httpd) et MariaDB sont tous les deux en cours d'exécution."
else
    warn_msg "Un ou plusieurs services LAMP ne sont pas actifs. Vérifiez manuellement (systemctl status httpd/mariadb)."
    warn_msg "Affichage des logs Apache pour le débogage:"
    journalctl -xeu httpd.service | tee -a "$LOG_FILE" # Affiche et log les logs Apache
    warn_msg "Affichage des logs MariaDB pour le débogage:"
    journalctl -xeu mariadb.service | tee -a "$LOG_FILE" # Affiche et log les logs MariaDB
fi

info_msg "---"
info_msg "Création d'un fichier info.php pour tester PHP..."
INFO_FILE="$WEB_ROOT/info.php"
# S'assurer que le répertoire web_root existe
if [ ! -d "$WEB_ROOT" ]; then
    sudo mkdir -p "$WEB_ROOT"
    sudo chown apache:apache "$WEB_ROOT"
    sudo chmod 755 "$WEB_ROOT"
fi

if echo "<?php phpinfo(); ?>" | sudo tee "$INFO_FILE" > /dev/null; then
    success_msg "Fichier info.php créé dans $WEB_ROOT."
    info_msg "Vous pouvez vérifier l'installation de PHP en visitant http://votre_adresse_ip/info.php dans votre navigateur."
else
    warn_msg "Échec de la création du fichier info.php. Vérifiez les permissions de $WEB_ROOT."
fi

# --- Étape 6: Nettoyage et finalisation ---
info_msg "---"
info_msg "Nettoyage des paquets inutiles..."
if sudo $PKG_MANAGER -y autoremove && sudo $PKG_MANAGER clean all; then
    success_msg "Nettoyage des paquets terminé."
else
    warn_msg "Échec du nettoyage des paquets."
fi

info_msg "---"
success_msg "Installation LAMP sur CentOS terminée avec succès !"
warn_msg "Pour des raisons de sécurité, n'oubliez pas de supprimer le fichier info.php après utilisation avec la commande:"
warn_msg "sudo rm $INFO_FILE"
info_msg "---"