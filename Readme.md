# 🚀 Script d'Installation LAMP Perfectionné

---

## Table des Matières

- [À Propos](#-à-propos)
- [Fonctionnalités](#-fonctionnalités)
- [Prérequis](#-prérequis)
- [Utilisation](#-utilisation)
- [Options du Script](#-options-du-script)
- [Configuration](#-configuration)
- [Vérification Post-Installation](#-vérification-post-installation)
- [Sécurité MySQL](#-sécurité-mysql)
- [Nettoyage](#-nettoyage)
- [Support et Contributions](#-support-et-contributions)
- [Licence](#-licence)

---

## 💡 À Propos

Ce script Bash est conçu pour automatiser l'installation et la configuration d'un environnement **LAMP** (Linux, Apache, MySQL, PHP) sur les systèmes d'exploitation basés sur Debian/Ubuntu. Il vise à simplifier le processus de mise en place d'un serveur de développement web local ou d'un serveur de production basique, en assurant une installation robuste avec des vérifications et des retours clairs.

---

## ✨ Fonctionnalités

* **Installation Complète** : Installe Apache, MySQL Server et PHP avec les modules courants.
* **Vérification de la Distribution** : S'assure que le script s'exécute sur une distribution compatible (Debian/Ubuntu).
* **Confirmation Utilisateur** : Demande une confirmation avant de démarrer l'installation pour éviter les exécutions accidentelles.
* **Messages Colorés** : Utilise des couleurs ANSI pour des messages clairs (informations, succès, avertissements, erreurs).
* **Journalisation (Logging)** : Enregistre toute la sortie du script dans un fichier de log horodaté pour faciliter le débogage.
* **Sécurisation MySQL** : Lance l'assistant de sécurisation MySQL (`mysql_secure_installation`).
* **Installation de PHP Spécifique** : Permet de choisir une version spécifique de PHP et ses modules.
* **Vérifications des Services** : Confirme que les services Apache et MySQL sont actifs après l'installation.
* **Fichier `info.php`** : Crée un fichier de test pour vérifier la configuration PHP.
* **Nettoyage Automatique** : Effectue un `apt autoremove` et `apt clean` pour supprimer les paquets inutiles et libérer de l'espace.
* **Option d'Aide** : Fournit une option `--help` pour afficher les instructions d'utilisation.

---

## 📋 Prérequis

* Un système d'exploitation basé sur Debian ou Ubuntu (par exemple, Ubuntu 20.04, 22.04, Debian 11, 12).
* Un accès `sudo` (le script doit être exécuté en tant que `root` ou avec `sudo`).
* Une connexion Internet active.

---

## 🚀 Utilisation

1.  **Téléchargez le script** :
    ```bash
    git clone [https://github.com/NABEDE/LAMP_UBUNTU.git](https://github.com/NABEDE/LAMP_UBUNTU.git)
    cd votre_depot
    # Ou téléchargez directement le fichier si vous n'avez pas de dépôt git
    # wget [https://raw.githubusercontent.com/NABEDE/LAMP_UBUNTU/master/lamp_ubuntu.sh](https://raw.githubusercontent.com/NABEDE/LAMP_UBUNTU/master/lamp_ubuntu.sh)
    ```

2.  **Rendez le script exécutable** :
    ```bash
    chmod +x lamp_ubuntu.sh
    ```

3.  **Exécutez le script** (en tant que `root` ou avec `sudo`) :
    ```bash
    sudo ./lamp_ubuntu.sh
    ```
    Le script vous demandera une confirmation avant de commencer l'installation.

---

## ⚙️ Options du Script

Vous pouvez utiliser les options suivantes lors de l'exécution du script :

* `--help` : Affiche le message d'aide et les options disponibles.
    ```bash
    sudo ./lamp_ubuntu.sh --help
    ```
* `--no-confirm` : Lance l'installation sans demander de confirmation à l'utilisateur.
    ```bash
    sudo ./lamp_ubuntu.sh --no-confirm
    ```

---

## 🔧 Configuration

Vous pouvez personnaliser l'installation en modifiant les variables au début du script `lamp_ubuntu.sh` :

```bash
# --- Variables de configuration ---
PHP_VERSION="8.1" # Exemple: "7.4", "8.1", etc. (doit être disponible dans les dépôts)
PHP_MODULES=(
    "php"
    "libapache2-mod-php"
    "php-mysql"
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
WEB_ROOT="/var/www/html" # Répertoire racine de votre site web Apache