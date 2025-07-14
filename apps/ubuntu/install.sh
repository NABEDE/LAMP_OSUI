#!/bin/bash

# ==============================================================================
# 🧰 Script d'Installation LAMP Perfectionné
# Installe et configure Apache, MySQL et PHP sur Debian/Ubuntu.
# Auteur: Jérôme N. | DevOps & Ingénieur Système Linux
# Date: 19 Juin 2025
# ==============================================================================

# --- 🎯 Variables de configuration ---
PHP_VERSION="8.1"
PHP_MODULES=(php${PHP_VERSION} libapache2-mod-php${PHP_VERSION} php${PHP_VERSION}-mysql php${PHP_VERSION}-cli php${PHP_VERSION}-json php${PHP_VERSION}-gd php${PHP_VERSION}-curl php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-intl php${PHP_VERSION}-soap)
WEB_ROOT="/var/www/html"
LOG_FILE="/var/log/lamp_install_$(date -u +%Y%m%d_%H%M%S).log"

../logo.sh

# Vérification du répertoire web root
if [ ! -d "$WEB_ROOT" ]; then
  mkdir -p "$WEB_ROOT"
fi

# --- 🎨 Couleurs ANSI ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

USE_COLOR=true  # Mettre à false pour désactiver les couleurs

# --- 📢 Fonctions d'affichage ---
log_msg() {
    # N'enregistre pas les codes couleurs dans le log
    local emoji="$1"
    local msg="$2"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $emoji $msg" >> "$LOG_FILE"
}

display_msg() {
    local color="$1"
    local emoji="$2"
    local msg="$3"
    if [ "$USE_COLOR" = true ]; then
        echo -e "${color}${emoji} $msg${NC}"
    else
        echo -e "${emoji} $msg"
    fi
    log_msg "$emoji" "$msg"
}

info_msg()    { display_msg "$BLUE"   "ℹ️"  "$1"; }
success_msg() { display_msg "$GREEN"  "✅"  "$1"; }
warn_msg()    { display_msg "$YELLOW" "⚠️"  "$1"; }
error_exit()  { display_msg "$RED"    "❌ ERREUR:" "$1" >&2; exit 1; }



# --- 🔧 Fonction d'Aide Optimisée ---
show_help() {
    # Affichage dans le terminal avec couleurs et emojis
    info_msg "📘 Utilisation : sudo ./ubuntu/install.sh [--no-confirm | --help]"
    echo -e "  ${GREEN}--help${NC}        Affiche ce message d'aide."
    echo -e "  ${GREEN}--no-confirm${NC}  Ne demande pas de confirmation utilisateur."
    warn_msg "⚠️ Assurez-vous d’avoir une connexion Internet active."

    # Ajout dans le log (sans couleur)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [HELP] Affichage de l'aide à l'utilisateur." >> "$LOG_FILE"
    exit 0
}



# --- 🧠 Traitement des arguments ---
NO_CONFIRM=false
UNKNOWN_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            show_help
            ;;
        --no-confirm)
            NO_CONFIRM=true
            ;;
        *)
            UNKNOWN_ARGS+=("$1")
            ;;
    esac
    shift
done

if [[ ${#UNKNOWN_ARGS[@]} -gt 0 ]]; then
    for arg in "${UNKNOWN_ARGS[@]}"; do
        warn_msg "Option inconnue : $arg"
    done
    show_help
fi
# ---- Fin de la partie --------


# --- 🔥 Fonction d'affichage du Logo ASCII Art ---
SCRIPT_NAME="LAMP INSTALLER"

show_logo() {
    info_msg "\n🚀 Lancement du script $SCRIPT_NAME pour Debian/Ubuntu"
    info_msg "${YELLOW}==============================${NC}"
    info_msg "${BLUE}    💡 $SCRIPT_NAME    ${NC}"
    info_msg "${YELLOW}==============================${NC}"
    success_msg "🎉 Bienvenue dans le script d'installation LAMP perfectionné !"
    echo ""
}

# Appel de la fonction (à placer au début du script)
show_logo



# --- ✅ Vérification des pré-requis ---

check_prerequisites() {
    [[ $EUID -ne 0 ]] && error_exit "Ce script doit être exécuté en tant que root (utilisez sudo)."

    info_msg "🌐 Vérification de la connexion Internet..."
    # Test réseau via HTTP (plus fiable que ping)
    if ! curl -s --head --connect-timeout 5 https://www.google.com | grep "200 OK" &> /dev/null; then
        error_exit "Pas de connexion Internet ou accès HTTP bloqué."
    fi

    command -v apt &> /dev/null || error_exit "Ce script est conçu pour les distributions APT (Debian/Ubuntu)."
}

# Appel de la fonction
check_prerequisites



# --- ✅ Confirmation utilisateur ---
if ! $NO_CONFIRM; then
    read -p "(echo -e \"${BLUE}⚙️ Voulez-vous démarrer l'installation LAMP ? (O/n) ${NC}\")" confirm
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



info_msg "🧪 Création du fichier info.php pour tester PHP..."

INFO_FILE="$WEB_ROOT/info.php"

# Vérifie si le dossier $WEB_ROOT existe, sinon le crée
if [ ! -d "$WEB_ROOT" ]; then
    info_msg "📂 Le dossier $WEB_ROOT n'existe pas. Création en cours..."
    mkdir -p "$WEB_ROOT" || error_exit "❌ Impossible de créer le dossier $WEB_ROOT."
fi

# Tente de créer le fichier info.php
if echo "<?php phpinfo(); ?>" > "$INFO_FILE"; then
    chown www-data:www-data "$INFO_FILE" 2>/dev/null || warn_msg "⚠️ Impossible de modifier le propriétaire de info.php (non critique)."
    chmod 644 "$INFO_FILE" || warn_msg "⚠️ Impossible de modifier les permissions de info.php (non critique)."
    success_msg "✅ Fichier info.php créé avec succès dans $WEB_ROOT."
    info_msg "🌐 Accédez à : http://localhost/info.php pour vérifier l'installation de PHP."
else
    error_exit "❌ Échec de la création de $INFO_FILE. Vérifiez les permissions."
fi



# --- 🧹 Nettoyage final ---
info_msg "🧹 Nettoyage du système..."
apt autoremove -y && apt clean \
    && success_msg "🧼 Système nettoyé." \
    || warn_msg "Nettoyage partiel ou échoué."

# --- 🎉 Fin ---
success_msg "🎉 Installation LAMP complétée avec succès !"
warn_msg "🧨 N'oubliez pas de supprimer info.php après vérification : sudo rm $INFO_FILE"
