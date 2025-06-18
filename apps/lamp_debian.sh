#! /bin/bash

# ==============================================================================
# Script d'Installation LAMP Perfectionné pour Debian
# Ce script installe et configure un environnement LAMP (Linux, Apache, MySQL, PHP)
# sur les systèmes basés sur Debian.
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
    echo -e "${BLUE}$1${NC}" | tee -a "$LOG_FILE" # Affiche de l'information en bleu gras et log
}

function success_msg {
    echo -e "${GREEN}$1${NC}" | tee -a "$LOG_FILE" # Affiche le succès en vert gras et log
}

# --- Fonction d'aide ---
function show_help {
    echo -e "${BLUE}Utilisation: sudo ./install_lamp.sh [options]${NC}"
    echo -e "${BLUE}Ce script installe un environnement LAMP (Linux, Apache, MySQL, PHP).${NC}"
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
info_msg "--- Script d'Installation LAMP Perfectionné ---"
info_msg "La sortie de ce script sera également enregistrée dans: ${LOG_FILE}"
info_msg "---"

# --- Pré-vérifications ---
# Vérifier si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   error_exit "Ce script doit être exécuté en tant que root. Utilisez 'sudo ./lamp_debian.sh'."
fi

#Une partie teste de connexion à internet
info_msg "Vérification de la connexion internet..."
if ! ping -c 1 google.com &> /dev/null; then
    error_exit "Impossible de se connecter à Internet. Veuillez vérifier votre connexion et réessayer."
else
    info_msg "Connexion Internet OK"
fi

# Vérifier la distribution (prend en charge Debian)
if ! command -v apt &> /dev/null; then
    error_exit "Ce script est conçu pour les systèmes basés sur Debian (APT). Votre système ne semble pas l'être."
fi

# Demander confirmation avant de commencer si --no-confirm n'est pas utilisé
if ! $NO_CONFIRM; then
    read -p "$(info_msg "Voulez-vous démarrer l'installation LAMP ? (O/n) ")" confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        info_msg "Installation annulée par l'utilisateur."
        exit 0
    fi
fi

info_msg "Démarrage de l'installation..."
info_msg "---"

# --- Étape 1: Mise à jour des paquets système ---
info_msg "Mise à jour des paquets système..."
if sudo apt update; then
    success_msg "Mise à jour des listes de paquets réussie."
else
    error_exit "Échec de la mise à jour des listes de paquets. Vérifiez votre connexion internet ou les dépôts APT."
fi

if sudo apt upgrade -y; then
    success_msg "Mise à niveau des paquets réussie."
else
    error_exit "Échec de la mise à niveau des paquets. Le script s'arrête."
fi

# --- Étape 2: Installation et configuration d'Apache ---
info_msg "---"
info_msg "Installation et configuration d'Apache..."
if sudo apt install apache2 -y; then
    success_msg "Apache installé avec succès."
else
    error_exit "Échec de l'installation d'Apache. Le script s'arrête."
fi

if sudo systemctl enable apache2; then
    success_msg "Apache activé pour démarrer au démarrage du système."
else
    warn_msg "Échec de l'activation d'Apache au démarrage. Veuillez vérifier manuellement."
fi

if sudo systemctl start apache2; then
    success_msg "Apache démarré avec succès."
else
    error_exit "Échec du démarrage d'Apache. Vérifiez les logs Apache pour plus de détails. Le script s'arrête."
    warn_msg "Affichage des logs Apache pour le débogage:"
    journalctl -xeu apache2.service | tee -a "$LOG_FILE" # Affiche et log les logs Apache
    error_exit "Échec du démarrage d'Apache. Vérifiez les logs Apache ci-dessus pour plus de détails. Le script s'arrête."
fi

if sudo systemctl enable mysql; then
    success_msg "MySQL activé pour démarrer au démarrage du système."
else
    warn_msg "Échec de l'activation de MySQL au démarrage. Veuillez vérifier manuellement."
     warn_msg "Échec de l'activation de MySQL au démarrage. Veuillez vérifier manuellement."
    warn_msg "Affichage des logs MySQL pour le débogage:"
    journalctl -xeu mysql.service | tee -a "$LOG_FILE" # Affiche et log les logs MySQL
fi

if sudo systemctl start mysql; then
    success_msg "MySQL démarré avec succès."
else
    error_exit "Échec du démarrage de MySQL. Vérifiez les logs MySQL pour plus de détails. Le script s'arrête."
     warn_msg "Affichage des logs MySQL pour le débogage:"
    journalctl -xeu mysql.service | tee -a "$LOG_FILE" # Affiche et log les logs MySQL
    error_exit "Échec du démarrage de MySQL. Vérifiez les logs MySQL ci-dessus pour plus de détails. Le script s'arrête."
fi


info_msg "---"
info_msg "Sécurisation de l'installation de MySQL..."
info_msg "Veuillez suivre attentivement les instructions qui vont apparaître pour définir un mot de passe ROOT pour MySQL et sécuriser votre installation."
if sudo mysql_secure_installation; then
    success_msg "Sécurisation de MySQL terminée avec succès."
else
    warn_msg "La sécurisation de MySQL n'a pas été complétée ou a rencontré des erreurs. Veuillez la faire manuellement plus tard (sudo mysql_secure_installation)."
fi

# --- Étape 4: Installation et configuration de PHP ---
info_msg "---"
info_msg "Installation de PHP ${PHP_VERSION} et des modules courants..."

# Construire la liste des modules PHP avec la version spécifiée
PHP_INSTALL_COMMAND=""
for module in "${PHP_MODULES[@]}"; do
    if [[ "$module" == "php" ]]; then
        PHP_INSTALL_COMMAND+="$module$PHP_VERSION "
    else
        PHP_INSTALL_COMMAND+="$module "
    fi
done

if sudo apt install $PHP_INSTALL_COMMAND -y; then
    success_msg "PHP ${PHP_VERSION} et ses modules installés avec succès."
else
    error_exit "Échec de l'installation de PHP ou de certains modules. Vérifiez si la version PHP ${PHP_VERSION} est disponible dans vos dépôts. Le script s'arrête."
fi

info_msg "---"
info_msg "Redémarrage d'Apache pour appliquer les changements PHP..."
if sudo systemctl restart apache2; then
    success_msg "Apache redémarré avec succès."
else
    error_exit "Échec du redémarrage d'Apache. Le script s'arrête."
fi

# --- Étape 5: Vérifications finales ---
info_msg "---"
info_msg "Vérification des versions installées:"
apache2 -v | head -n 1 | tee -a "$LOG_FILE"
mysql --version | tee -a "$LOG_FILE"
php -v | head -n 1 | tee -a "$LOG_FILE"


info_msg "---"
info_msg "Vérification de l'état des services:"
if systemctl is-active --quiet apache2 && systemctl is-active --quiet mysql; then
    success_msg "Apache et MySQL sont tous les deux en cours d'exécution."
else
    warn_msg "Un ou plusieurs services LAMP ne sont pas actifs. Vérifiez manuellement (systemctl status apache2/mysql)."
    warn_msg "Affichage des logs Apache pour le débogage:"
    journalctl -xeu apache2.service | tee -a "$LOG_FILE" # Affiche et log les logs Apache
    warn_msg "Affichage des logs MySQL pour le débogage:"
    journalctl -xeu mysql.service | tee -a "$LOG_FILE" # Affiche et log les logs MySQL
fi

info_msg "---"
info_msg "Création d'un fichier info.php pour tester PHP..."
INFO_FILE="$WEB_ROOT/info.php"
if echo "<?php phpinfo(); ?>" | sudo tee "$INFO_FILE" > /dev/null; then
    success_msg "Fichier info.php créé dans $WEB_ROOT."
    info_msg "Vous pouvez vérifier l'installation de PHP en visitant http://localhost/info.php dans votre navigateur."
else
    warn_msg "Échec de la création du fichier info.php. Vérifiez les permissions de $WEB_ROOT."
fi

# --- Étape 6: Nettoyage et finalisation ---
info_msg "---"
info_msg "Nettoyage des paquets inutiles..."
if sudo apt autoremove -y && sudo apt clean; then
    success_msg "Nettoyage des paquets terminé."
else
    warn_msg "Échec du nettoyage des paquets."
fi

info_msg "---"
success_msg "Installation LAMP terminée avec succès !"
warn_msg "Pour des raisons de sécurité, n'oubliez pas de supprimer le fichier info.php après utilisation avec la commande:"
warn_msg "sudo rm $INFO_FILE"
info_msg "---"