#!/bin/bash

# ==============================================================================
# 🧰 Script d'Installation LAMP Perfectionné 
# Installe et configure Apache, MySQL et PHP sur Debian/Ubuntu.
# Auteur: Jérôme N. | DevOps & Ingénieur Système Linux
# Date: 19 Juin 2025
# ==============================================================================

# --- 🎯 Variables de configuration ---
PHP_VERSION="8.1"
PHP_MODULES=(php libapache2-mod-php php-mysql php-cli php-json php-gd php-curl php-mbstring php-xml php-zip php-intl php-soap)
WEB_ROOT="/var/www/html"
LOG_FILE="lamp_install_$(date +%Y%m%d_%H%M%S).log"

# --- 🎨 Couleurs ANSI ---
RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; BLUE='\e[1;34m'; NC='\e[0m'

# --- 📢 Fonctions d'affichage ---
info_msg()    { echo -e "${BLUE}ℹ️ $1${NC}" | tee -a "$LOG_FILE"; }
success_msg() { echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"; }
warn_msg()    { echo -e "${YELLOW}⚠️ $1${NC}" | tee -a "$LOG_FILE"; }
error_exit()  { echo -e "${RED}❌ ERREUR: $1${NC}" | tee -a "$LOG_FILE" >&2; exit 1; }

# --- 🔧 Aide ---
show_help() {
    echo -e "${BLUE}📘 Utilisation : sudo ./lamp_ubuntu.sh [--no-confirm | --help]${NC}"
    echo -e "  ${GREEN}--help${NC}        Affiche ce message d'aide."
    echo -e "  ${GREEN}--no-confirm${NC}  Ne demande pas de confirmation utilisateur."
    echo -e "${YELLOW}⚠️ Assurez-vous d’avoir une connexion Internet active.${NC}"
    exit 0
}

# --- 🧠 Traitement des arguments ---
NO_CONFIRM=false
for arg in "$@"; do
    case "$arg" in
        --help) show_help ;;
        --no-confirm) NO_CONFIRM=true ;;
        *) warn_msg "Option inconnue: $arg"; show_help ;;
    esac
done

# --- 🔥 ASCII Art Logo ---
info_msg "
  ${YELLOW}**** **** **** ****${NC}
 ${YELLOW}* ${BLUE}L${YELLOW} * ${BLUE}A${YELLOW} * ${BLUE}M${YELLOW} * ${BLUE}P${YELLOW} *${NC}
${YELLOW}* * * * * * * *${NC}
${YELLOW}* ${BLUE}** ${YELLOW}** * ${RED}****${NC}
 ${YELLOW}* * * * * * *${NC}
  ${YELLOW}* * * * * *${NC}
   ${YELLOW}**** **** **** ****${NC}
"
success_msg "🎉 Bienvenue dans le script d'installation LAMP perfectionné !"

# --- ✅ Pré-requis ---
[[ $EUID -ne 0 ]] && error_exit "Ce script doit être exécuté en tant que root (utilisez sudo)."

info_msg "🌐 Vérification de la connexion Internet..."
ping -c 1 google.com &> /dev/null || error_exit "Pas de connexion Internet."

command -v apt &> /dev/null || error_exit "Ce script est conçu pour les distributions APT (Debian/Ubuntu)."

# --- ✅ Confirmation utilisateur ---
if ! $NO_CONFIRM; then
    read -p "$(echo -e "${BLUE}⚙️ Voulez-vous démarrer l'installation LAMP ? (O/n) ${NC}")" confirm
    [[ "$confirm" =~ ^[Nn]$ ]] && info_msg "🚫 Installation annulée." && exit 0
fi

# --- 🧱 Mise à jour du système ---
info_msg "🔄 Mise à jour du système..."
apt update && apt upgrade -y \
    && success_msg "🆗 Système mis à jour." \
    || error_exit "Impossible de mettre à jour le système."

# --- 🌐 Installation et activation de Apache ---
info_msg "🚀 Installation d'Apache..."
apt install -y apache2 \
    && systemctl enable apache2 \
    && systemctl start apache2 \
    && success_msg "🟢 Apache est installé et actif." \
    || error_exit "Impossible d’installer ou de démarrer Apache."

# --- 🛢️ Installation de MySQL ou MariaDB ---
info_msg "🛠️ Installation de MySQL Server..."
apt install -y mysql-server || error_exit "Échec de l'installation de MySQL."

systemctl enable mysql && systemctl start mysql \
    && success_msg "🟢 MySQL est installé et actif." \
    || error_exit "Échec du démarrage de MySQL."

info_msg "🔐 Sécurisation de MySQL..."
mysql_secure_installation || warn_msg "Vous pouvez relancer cette commande plus tard : sudo mysql_secure_installation"

# --- ⚙️ Installation de PHP et modules ---
info_msg "📦 Installation de PHP $PHP_VERSION et modules associés..."
PHP_INSTALL_COMMAND=""
for module in "${PHP_MODULES[@]}"; do
    if [[ "$module" == "php" ]]; then
        PHP_INSTALL_COMMAND+="$module$PHP_VERSION "
    else
        PHP_INSTALL_COMMAND+="$module "
    fi
done

apt install -y $PHP_INSTALL_COMMAND \
    && success_msg "🧠 PHP $PHP_VERSION installé avec ses modules." \
    || error_exit "Échec lors de l'installation de PHP."

systemctl restart apache2 || error_exit "❌ Apache n’a pas pu être redémarré après l’installation de PHP."

# --- 🔍 Vérifications finales ---
info_msg "🔎 Vérification des versions installées :"
apache2 -v | head -n 1 | tee -a "$LOG_FILE"
mysql --version | tee -a "$LOG_FILE"
php -v | head -n 1 | tee -a "$LOG_FILE"

# --- 🧪 Vérification de l’état des services ---
info_msg "📊 Vérification des services :"
for svc in apache2 mysql; do
    if systemctl is-active --quiet "$svc"; then
        success_msg "✅ Le service $svc est actif."
    else
        warn_msg "❗ Le service $svc est inactif. Vérifiez avec : systemctl status $svc"
        journalctl -xeu "$svc" | tee -a "$LOG_FILE"
    fi
done

# --- 📄 Fichier info.php ---
info_msg "🧪 Création du fichier info.php pour tester PHP..."
INFO_FILE="$WEB_ROOT/info.php"
echo "<?php phpinfo(); ?>" | tee "$INFO_FILE" > /dev/null \
    && success_msg "Fichier info.php créé dans $WEB_ROOT." \
    && info_msg "🌐 Accédez à http://localhost/info.php pour tester PHP." \
    || warn_msg "Impossible de créer le fichier info.php. Vérifiez les permissions."

# --- 🧹 Nettoyage final ---
info_msg "🧹 Nettoyage du système..."
apt autoremove -y && apt clean \
    && success_msg "🧼 Système nettoyé." \
    || warn_msg "Nettoyage partiel ou échoué."

# --- 🎉 Fin ---
success_msg "🎉 Installation LAMP complétée avec succès !"
warn_msg "🧨 N'oubliez pas de supprimer info.php après vérification : sudo rm $INFO_FILE"
