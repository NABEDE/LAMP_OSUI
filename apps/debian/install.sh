#! /bin/bash

# ============================================================================== 
# 🛠️ Script d'Installation LAMP Perfectionné pour Debian
# Auteur: Jérôme N. | Ingénieur Système Réseau | DevOps Linux & Docker
# Date: 19 Juin 2025 
# ==============================================================================

# --- 🔢 Variables de configuration ---
PHP_VERSION="8.1"
PHP_MODULES=(php php-mysqlnd php-cli php-json php-gd php-curl php-mbstring php-xml php-zip php-intl php-soap)
WEB_ROOT="/var/www/html"
LOG_FILE="lamp_install_$(date +%Y%m%d_%H%M%S).log"

# --- 🎨 Couleurs ---
RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; BLUE='\e[1;34m'; NC='\e[0m'

# --- 💬 Fonctions de log ---
info_msg()    { echo -e "${BLUE}ℹ️ $1${NC}" | tee -a "$LOG_FILE"; }
success_msg() { echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"; }
warn_msg()    { echo -e "${YELLOW}⚠️ $1${NC}" | tee -a "$LOG_FILE"; }
error_exit()  { echo -e "${RED}❌ ERREUR: $1${NC}" | tee -a "$LOG_FILE" >&2; exit 1; }

# --- 🕵️‍ Fonction d'aide ---
show_help() {
    echo -e "${BLUE}📃 Utilisation: sudo ./apps/debian/install.sh [--no-confirm | --help]${NC}"
    echo -e "  ${GREEN}--help${NC}        Affiche ce message d'aide."
    echo -e "  ${GREEN}--no-confirm${NC}  Ne demande pas de confirmation utilisateur."
    echo -e "${YELLOW}⚠️ Assurez-vous d’avoir une connexion Internet active.${NC}"
    exit 0
}

# 📦 Détection de la version de Debian
DEBIAN_VERSION=$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)
info_msg "🖥️  Version de Debian détectée : $DEBIAN_VERSION"

# Fonction pour installer mysql depuis le dépôt officiel Oracle
install_mysql_official_repo() {
    info_msg "🌐 Ajout du dépôt officiel MySQL (Oracle)..."
    wget -q https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb || error_exit "❌ Échec du téléchargement du dépôt MySQL."
    DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.29-1_all.deb
    apt update || error_exit "❌ Échec de mise à jour après ajout du dépôt MySQL."
    apt install -y mysql-server && return 0 || return 1
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

# --- 🌟 Logo ---
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

# --- 🛠️ Installation ---
info_msg "🔄 Mise à jour du système..."
apt update && apt upgrade -y || error_exit "Impossible de mettre à jour."

info_msg "🚀 Installation d'Apache..."
apt install -y apache2 && systemctl enable apache2 && systemctl start apache2 \
    && success_msg "Apache installé et actif." || error_exit "Apache a échoué."


# 🔍 Détection du package MySQL ou MariaDB disponible
MYSQL_PKG=""
if apt-cache show mysql-server &>/dev/null; then
    MYSQL_PKG="mysql-server"
elif apt-cache show mariadb-server &>/dev/null; then
    MYSQL_PKG="mariadb-server"
else
    error_exit "Aucun paquet MySQL ou MariaDB disponible dans les dépôts APT."
fi


# 💰 Installation de MySQL ou MariaDB ( Travail sur ceci )
MYSQL_PKG="mysql-server"
info_msg "💰 Tentative d'installation de $MYSQL_PKG..."
if ! apt install -y "$MYSQL_PKG"; then
    warn_msg "❌ $MYSQL_PKG indisponible ou échoué. Tentative avec mariadb-server..."
    MYSQL_PKG="mariadb-server"
    if ! apt install -y "$MYSQL_PKG"; then
        error_exit "🚫 Aucune installation possible pour MySQL ou MariaDB. Vérifiez les dépôts."
    else
        success_msg "✅ $MYSQL_PKG installé avec succès."
    fi
else
    success_msg "✅ $MYSQL_PKG installé avec succès."
fi

# 💰 Tentative d'installation native de MySQL
MYSQL_PKG="mysql-server"
info_msg "💰 Tentative d'installation de $MYSQL_PKG depuis les dépôts Debian..."

if ! apt install -y "$MYSQL_PKG"; then
    warn_msg "❌ $MYSQL_PKG indisponible dans les dépôts natifs."

    # Cas Debian 11 et plus : proposer dépôt officiel
    if [[ "$DEBIAN_VERSION" -ge 11 ]]; then
        info_msg "🔁 Debian $DEBIAN_VERSION : Ajout du dépôt Oracle recommandé."
        if install_mysql_official_repo; then
            success_msg "✅ MySQL installé avec succès via le dépôt officiel."
            exit 0
        else
            warn_msg "❌ Installation MySQL échouée via le dépôt Oracle."
        fi
    else
        warn_msg "ℹ️ Debian $DEBIAN_VERSION : MySQL non pris en charge directement. Tentative avec MariaDB..."
    fi

    # 🔄 Tentative avec MariaDB (alternative 100% compatible)
    MYSQL_PKG="mariadb-server"
    if ! apt install -y "$MYSQL_PKG"; then
        error_exit "🚫 Échec d'installation de MySQL et MariaDB. Vérifiez vos sources APT."
    else
        success_msg "✅ $MYSQL_PKG installé avec succès comme alternative."
    fi
else
    success_msg "✅ $MYSQL_PKG installé avec succès."
fi

# ( La partie sur laquelle il faut travailler )

# 🔄 Détection dynamique du service MySQL/MariaDB
detect_mysql_service() {
    for svc in mysql mariadb mysqld; do
        if systemctl list-unit-files | grep -q "^${svc}.service"; then
            echo "$svc"
            return
        fi
    done
    echo "" # Aucun trouvé
}

MYSQL_SERVICE=$(detect_mysql_service)
if [[ -z "$MYSQL_SERVICE" ]]; then
    error_exit "🚫 Aucun service MySQL/MariaDB détecté. Abandon."
fi

# 🚀 Activation + Démarrage du service
info_msg "⚙️ Activation et démarrage du service : $MYSQL_SERVICE"
#systemctl enable "$MYSQL_SERVICE" || warn_msg "⚠️ Impossible d'activer $MYSQL_SERVICE au démarrage."
#systemctl start "$MYSQL_SERVICE" || error_exit "🚫 Impossible de démarrer le service $MYSQL_SERVICE."
service enable "$MYSQL_SERVICE" || warn_msg "⚠️ Impossible d'activer $MYSQL_SERVICE au démarrage."
service "$MYSQL_SERVICE" || error_exit "🚫 Impossible de démarrer le service $MYSQL_SERVICE."


# 🔐 Sécurisation
info_msg "🔐 Sécurisation de l'installation de $MYSQL_SERVICE..."
if command -v mysql_secure_installation &> /dev/null; then
    mysql_secure_installation || warn_msg "⚠️ mysql_secure_installation interrompu. Relancez manuellement : sudo mysql_secure_installation"
else
    warn_msg "ℹ️ mysql_secure_installation n'est pas disponible. Peut ne pas être nécessaire avec MariaDB."
fi



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

systemctl restart apache2 || error_exit "Apache n’a pas pu être redémarré."

# --- 🔍 Vérifications finales ---
info_msg "🔢 Versions installées :"
apache2 -v | head -n 1 | tee -a "$LOG_FILE"
mysql --version | tee -a "$LOG_FILE"
php -v | head -n 1 | tee -a "$LOG_FILE"

info_msg "🔎 Services en cours :"
for svc in apache2 mysql; do
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
