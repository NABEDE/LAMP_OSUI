#!/bin/bash

# 📁 Définir le fichier de log
export LOG_FILE="/tmp/test_error_exit.log"
> "$LOG_FILE"  # Vider le fichier avant test

# 🧩 Importer la fonction depuis le fichier externe
source ./debian/install.sh

# 🧪 Test de error_exit dans un sous-shell
(
  echo "🔧 Début du test"
  error_exit "Test d’erreur fatale"
  echo "🛠️ Ceci ne devrait pas s’afficher"
)

# 📋 Vérifier le contenu du fichier de log
echo "📁 Contenu du log :"
cat "$LOG_FILE"

# ✅ Vérification du résultat
if grep -q "Test d’erreur fatale" "$LOG_FILE"; then
    echo "✅ Test réussi : message bien loggé."
else
    echo "❌ Test échoué : message non trouvé."
fi
