#! /bin/bash

# ============================================================================== 
# 🛠️ Script d'Installation LAMP Perfectionné pour Debian
# Auteur: Jérôme N. | 👨‍💻 Ingénieur Système Réseau | 🚀 DevOps Linux & Docker
# Version: 1.2 | 📅 Mise à jour: 10 juillet 2025
# ==============================================================================



# --- 🔢 Variables de configuration ---
PHP_VERSION="8.1"
# Modules PHP à installer (modifiez selon vos besoins)
PHP_MODULES=(
    php
    php-mysqlnd
    php-cli
    php-json
    php-gd
    php-curl
    php-mbstring
    php-xml
    php-zip
    php-intl
    php-soap
)

WEB_ROOT="/var/www/html"

# Dossier de logs dédié
LOG_DIR="/var/log/lamp"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/lamp_install_$(date +%Y%m%d_%H%M%S).log"

# Vérification de la version de PHP
if [[ -z "$PHP_VERSION" ]]; then
    echo "La variable PHP_VERSION n'est pas définie !" | tee -a "$LOG_FILE"
    exit 1
fi

# Vérification de l'existence du dossier web root
if [[ ! -d "$WEB_ROOT" ]]; then
    echo "Le dossier WEB_ROOT ($WEB_ROOT) n'existe pas. Création..." | tee -a "$LOG_FILE"
    mkdir -p "$WEB_ROOT"
fi

# ---- Fin de la première partie du code ------



# --- 🎨 Couleurs ---
if [ -t 1 ]; then
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi



# --- 💬 Fonctions de log ---

log_msg() {
    local color="$1"
    local icon="$2"
    local msg="$3"
    local level="$4"
    local datetime
    datetime="$(date +'%Y-%m-%d %H:%M:%S')"

    # Message formaté
    local formatted="${color}${icon} [${datetime}] ${msg}${NC}"

    # Écriture
    if [ "$level" = "ERROR" ]; then
        echo -e "$formatted" | tee -a "$LOG_FILE" >&2
        exit 1
    else
        echo -e "$formatted" | tee -a "$LOG_FILE"
    fi
}

info_msg()    { log_msg "$BLUE"   "ℹ️" "$1" "INFO"; }
success_msg() { log_msg "$GREEN"  "✅" "$1" "SUCCESS"; }
warn_msg()    { log_msg "$YELLOW" "⚠️" "$1" "WARN"; }
error_exit()  { log_msg "$RED"    "❌ ERREUR:" "$1" "ERROR"; }

# ---- Fin de la partie ---------





# --- 🕵️ Fonction d'aide ---
show_help() {
    echo -e "${BLUE}📃 Utilisation : sudo ./apps/debian/install.sh [OPTIONS]${NC}"
    echo -e "${GREEN}Options disponibles :${NC}"
    echo -e "  ${GREEN}--help${NC}        Affiche ce message d'aide."
    echo -e "  ${GREEN}--no-confirm${NC}  Ne demande pas de confirmation utilisateur."
    echo -e "${GREEN}Exemple :${NC}"
    echo -e "  sudo ./apps/debian/install.sh --no-confirm"
    echo -e "${YELLOW}⚠️ Assurez-vous d’avoir :${NC}"
    echo -e "    - Une connexion Internet active"
    echo -e "    - Les droits administrateur (sudo)"
    echo -e "    - Un système Debian compatible"
    exit 0
}
# ------- Fin de la partie ----------------




# --- 🔍 Détection version Debian ---
if [ -f /etc/os-release ]; then
    DEBIAN_VERSION=$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)
    DEBIAN_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f 2 | tr -d '"')
    if [ -z "$DEBIAN_VERSION" ]; then
        warn_msg "Impossible de détecter la version de Debian."
    else
        info_msg "🖥️  Version de Debian détectée : $DEBIAN_VERSION ($DEBIAN_NAME)"
    fi
else
    error_exit "Fichier /etc/os-release introuvable. Impossible de détecter la version de Debian."
fi

# --- 🧠 Traitement des arguments ---
NO_CONFIRM=false
UNKNOWN_ARGS=()

for arg in "$@"; do
    case "$arg" in
        --help)
            show_help
            ;;
        --no-confirm)
            NO_CONFIRM=true
            ;;
        *)
            UNKNOWN_ARGS+=("$arg")
            ;;
    esac
done

if [ ${#UNKNOWN_ARGS[@]} -ne 0 ]; then
    for unknown in "${UNKNOWN_ARGS[@]}"; do
        warn_msg "Option inconnue : $unknown"
    done
    show_help
fi


# ------ Fin de la partie ---------






# --- 🌟 Logo & intro ---
info_msg "\n🚀 Démarrage du script d'installation LAMP pour Debian"
success_msg "✨ Tous les journaux seront sauvegardés dans : $LOG_FILE"

# --- 🚧 Vérifications préalables ---
[[ $EUID -ne 0 ]] && error_exit "Ce script doit être exécuté en tant que root."
ping -c 1 google.com &>/dev/null || error_exit "Connexion Internet indisponible."
command -v apt &>/dev/null || error_exit "Ce script est conçu pour Debian (APT)."

if ! $NO_CONFIRM; then
    read -p $'\e[1;34m❓ Voulez-vous lancer l\'installation LAMP ? (O/n) \e[0m' confirm
    [[ "$confirm" =~ ^[Nn]$ ]] && info_msg "❌ Installation annulée." && exit 0
fi

# --- 🔄 Mise à jour ---
info_msg "🔄 Mise à jour du système..."
apt update && apt upgrade -y || error_exit "Impossible de mettre à jour."

# --- 🌐 Installation Apache ---
info_msg "🚀 Installation d'Apache..."
apt install -y apache2 && systemctl enable apache2 && systemctl start apache2 \
    && success_msg "Apache installé et actif." || error_exit "Apache a échoué."

# --- 💰 Installation MySQL/MariaDB ---
info_msg "🔍 Détection du package MySQL ou MariaDB..."
MYSQL_PKG=""
if apt-cache show mysql-server &>/dev/null; then
    MYSQL_PKG="mysql-server"
elif apt-cache show mariadb-server &>/dev/null; then
    MYSQL_PKG="mariadb-server"
else
    error_exit "Aucun paquet MySQL ou MariaDB disponible dans les dépôts APT."
fi

info_msg "💰 Installation de $MYSQL_PKG..."
if ! apt install -y "$MYSQL_PKG"; then
    warn_msg "❌ $MYSQL_PKG indisponible ou échoué."
    if [[ "$DEBIAN_VERSION" -ge 11 ]]; then
        info_msg "📦 Ajout du dépôt officiel MySQL (Oracle)..."
        wget -q https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb || error_exit "Téléchargement MySQL échoué."
        DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.29-1_all.deb
        apt update
        apt install -y mysql-server || apt install -y mariadb-server || error_exit "Échec complet de l'installation MySQL/MariaDB."
        MYSQL_PKG=$(detect_mysql_service)
    else
        apt install -y mariadb-server || error_exit "MariaDB aussi a échoué."
    fi
else
    success_msg "✅ $MYSQL_PKG installé avec succès."
fi

# --- 🔄 Activation et démarrage MySQL/MariaDB ---
detect_mysql_service() {
    for svc in mysql mariadb mysqld; do
        if systemctl list-unit-files | grep -q "^${svc}.service"; then
            echo "$svc"
            return
        fi
    done
    echo ""
}

MYSQL_SERVICE=$(detect_mysql_service)
[[ -z "$MYSQL_SERVICE" ]] && error_exit "🚫 Aucun service MySQL/MariaDB détecté."
info_msg "⚙️ Activation et démarrage du service : $MYSQL_SERVICE"
systemctl enable "$MYSQL_SERVICE" || warn_msg "⚠️ Impossible d'activer $MYSQL_SERVICE."
systemctl start "$MYSQL_SERVICE" || error_exit "🚫 Démarrage de $MYSQL_SERVICE échoué."

# --- 🔐 Sécurisation ---
info_msg "🔐 Sécurisation de l'installation..."
if command -v mysql_secure_installation &>/dev/null; then
    mysql_secure_installation || warn_msg "mysql_secure_installation non complété."
else
    warn_msg "mysql_secure_installation indisponible."
fi

# --- 👾 Installation PHP ---
info_msg "👾 Installation de PHP $PHP_VERSION et ses modules..."
PHP_INSTALL_COMMAND=""
for module in "${PHP_MODULES[@]}"; do
    if [[ "$module" == "php" ]]; then
        PHP_INSTALL_COMMAND+="$module$PHP_VERSION "
    else
        PHP_INSTALL_COMMAND+="$module "
    fi
done
apt install -y $PHP_INSTALL_COMMAND || error_exit "PHP ou modules non disponibles."
systemctl restart apache2 || error_exit "Redémarrage Apache échoué."

# --- 🔍 Vérifications finales ---
info_msg "🔢 Versions installées :"
apache2 -v | head -n 1 | tee -a "$LOG_FILE"
mysql --version | tee -a "$LOG_FILE"
php -v | head -n 1 | tee -a "$LOG_FILE"

info_msg "🔎 Services en cours :"
for svc in apache2 "$MYSQL_SERVICE"; do
    systemctl is-active --quiet $svc \
        && success_msg "$svc est actif." \
        || { warn_msg "$svc est inactif."; journalctl -xeu $svc | tee -a "$LOG_FILE"; }
done

# --- 🔧 Test PHP ---
INFO_FILE="$WEB_ROOT/info.php"
echo "<?php phpinfo(); ?>" > "$INFO_FILE" \
    && success_msg "Fichier info.php créé." \
    && info_msg "Testez sur : http://localhost/info.php" \
    || warn_msg "Impossible de créer info.php."

# --- 🪜 Nettoyage ---
info_msg "🪜 Nettoyage..."
apt autoremove -y && apt clean && success_msg "Nettoyage terminé."

# --- 🎉 Fin ---
success_msg "🎉 Installation LAMP terminée avec succès !"
warn_msg "⚠️ Supprimez info.php après usage : sudo rm $INFO_FILE"
