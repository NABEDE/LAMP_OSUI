#!/bin/bash

source ../logo.sh

# ==============================================================================
# 🚀 Script d'Installation LAMP Perfectionné pour AlmaLinux
# Auteur : Jérôme N. | 👨‍💻 Ingénieur Système Réseau | 🚀 DevOps Microservices Linux & Docker
# Version : 1.1 - Date : 10 juillet 2025
# ==============================================================================

# ------------------ 📁 Variables de configuration ------------------
PHP_VERSION="8.1"
PHP_MODULES=(
    "php"
    "php-mysqlnd"
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
LOG_FILE="lamp_install_$(date +%Y%m%d_%H%M%S).log"

# ------------------ 🌌 Codes couleur ------------------
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
NC='\e[0m'

# ------------------ ⚠️ Gestion des interruptions ------------------
trap "echo -e '\n${RED}Script interrompu. Nettoyage et sortie.${NC}'; exit 1" INT TERM

# ------------------ 📈 Fonctions d'affichage ------------------
function error_exit { echo -e "${RED}❌ ERREUR: $1${NC}" | tee -a "$LOG_FILE" >&2; exit 1; }
function info_msg { echo -e "${BLUE}ℹ️ $1${NC}" | tee -a "$LOG_FILE"; }
function success_msg { echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"; }
function warn_msg { echo -e "${YELLOW}⚠️ AVERTISSEMENT: $1${NC}" | tee -a "$LOG_FILE"; }

# ------------------ ❓ Aide ------------------
function show_help {
    echo -e "${BLUE}📚 Utilisation : sudo ./install.sh [--no-confirm]${NC}"
    echo -e "${BLUE}Ce script installe Apache, MariaDB et PHP sur AlmaLinux.${NC}"
    echo -e "${GREEN}--help${NC}         Affiche ce message."
    echo -e "${GREEN}--no-confirm${NC}   Ne demande pas de confirmation."
    exit 0
}

# ------------------ 📲 Argument CLI ------------------
NO_CONFIRM=false
for arg in "$@"; do
    case "$arg" in
        --help) show_help ;;
        --no-confirm) NO_CONFIRM=true ;;
        *) warn_msg "Option inconnue: $arg"; show_help ;;
    esac
done

# ------------------ 🌐 Fonctions utilitaires ------------------
function enable_service {
    local service=$1
    if systemctl enable "$service"; then
        success_msg "Le service $service a été activé pour le démarrage automatique."
    else
        warn_msg "Impossible d'activer $service."
    fi
}

function start_service {
    local service=$1
    if systemctl start "$service"; then
        success_msg "$service a été démarré avec succès."
    else
        warn_msg "Impossible de démarrer $service. Logs :"
        journalctl -xeu "$service" | tee -a "$LOG_FILE"
        error_exit "$service n'a pas pu démarrer."
    fi
}

function check_service {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        success_msg "$service est actif."
    else
        warn_msg "$service est inactif. Logs :"
        journalctl -xeu "$service" | tee -a "$LOG_FILE"
    fi
}

# ------------------ 🔍 Pré-vérifications ------------------
info_msg "--- 🚀 Démarrage de l'installation LAMP pour AlmaLinux ---"
info_msg "🔝 Les journaux seront enregistrés dans : $LOG_FILE"

if [[ $EUID -ne 0 ]]; then
    error_exit "Ce script doit être exécuté en tant que root (sudo)."
fi

if command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
else
    error_exit "Le gestionnaire de paquets DNF est requis."
fi

if ! ping -c 1 google.com &>/dev/null; then
    error_exit "Pas de connexion Internet. Veuillez vérifier votre réseau."
fi

if ! grep -qE "AlmaLinux|Red Hat" /etc/redhat-release; then
    error_exit "Ce script est uniquement compatible avec AlmaLinux ou RHEL."
fi

if ! $NO_CONFIRM; then
    read -p "🚀 Voulez-vous commencer l'installation ? (O/n) " confirm
    confirm=${confirm,,}
    [[ "$confirm" =~ ^(n|non)$ ]] && info_msg "Installation annulée par l'utilisateur." && exit 0
fi

# ------------------ ♻️ Mise à jour ------------------
info_msg "Mise à jour du système..."
$PKG_MANAGER -y update || error_exit "❌ La mise à jour a échoué."

# ------------------ 🌐 Apache ------------------
info_msg "Installation d'Apache..."
$PKG_MANAGER -y install httpd || error_exit "❌ Échec de l'installation d'Apache."
enable_service httpd
start_service httpd

# Pare-feu
if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    success_msg "🔒 Règles du pare-feu HTTP/HTTPS appliquées."
else
    warn_msg "firewalld inactif, pare-feu non configuré."
fi

# ------------------ 📅 MariaDB ------------------
info_msg "Installation de MariaDB (MySQL)..."
$PKG_MANAGER -y install mariadb-server mariadb || error_exit "❌ MariaDB échec."
enable_service mariadb
start_service mariadb

info_msg "⚖️ Sécurisation de MariaDB via mysql_secure_installation..."
mysql_secure_installation || warn_msg "Sécurisation MariaDB non complète."

# ------------------ 💁 PHP ------------------
info_msg "Installation de PHP $PHP_VERSION et ses modules..."
$PKG_MANAGER -y install epel-release
$PKG_MANAGER -y install https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm
$PKG_MANAGER module -y reset php
$PKG_MANAGER module -y enable php:remi-${PHP_VERSION//./}
$PKG_MANAGER -y install ${PHP_MODULES[*]} || error_exit "❌ Installation PHP échec."

systemctl restart httpd || error_exit "❌ Impossible de redémarrer Apache."

# ------------------ 🔢 Vérifications ------------------
info_msg "--- ✅ Vérifications des versions ---"
httpd -v | head -n1 | tee -a "$LOG_FILE"
mysql --version | tee -a "$LOG_FILE"
php -v | head -n1 | tee -a "$LOG_FILE"

check_service httpd
check_service mariadb

# ------------------ 🔧 Test PHP ------------------
INFO_FILE="$WEB_ROOT/info.php"
[ ! -d "$WEB_ROOT" ] && mkdir -p "$WEB_ROOT" && chown apache:apache "$WEB_ROOT" && chmod 755 "$WEB_ROOT"
echo "<?php phpinfo(); ?>" > "$INFO_FILE" && success_msg "🌐 info.php créé : http://votre_ip/info.php"

# ------------------ 🧹 Nettoyage ------------------
info_msg "Nettoyage du système..."
$PKG_MANAGER -y autoremove && $PKG_MANAGER clean all

success_msg "🎉 Installation LAMP terminée avec succès !"
warn_msg "⚠️ Pensez à supprimer $INFO_FILE pour des raisons de sécurité."
info_msg "--- 🌟 Fin du script ---"
