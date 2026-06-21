#!/bin/bash
# =============================================================================
# Script de révocation de TOUTES les autorisations XP SafeConnect Monitored App
# =============================================================================
# Ce script supprime toutes les autorisations accordées à l'application surveillée
# (10 autorisations principales) pour permettre de tester à nouveau 
# le processus d'acquisition des permissions.
#
# Usage: 
#   - Via ADB: adb shell sh /chemin/vers/revoke_all_permissions.sh
#   - Via Termux: sh /chemin/vers/revoke_all_permissions.sh
#   - Via ADB PC: adb push revoke_all_permissions.sh /data/local/tmp/ && adb shell sh /data/local/tmp/revoke_all_permissions.sh
# =============================================================================

PACKAGE_NAME="com.xpsafeconnect.monitored_app"

echo "========================================"
echo "XP SafeConnect - Révocation des autorisations"
echo "========================================"
echo ""
echo "Package: $PACKAGE_NAME"
echo ""

# -----------------------------------------------------------------------------
# 1. DEVICE ADMIN (Anti-Uninstall)
# -----------------------------------------------------------------------------
echo "[1/10] Suppression du Device Admin..."
dpm remove-active-admin $PACKAGE_NAME/.AntiUninstallAdmin 2>/dev/null
[ $? -eq 0 ] && echo "  [OK] Device Admin supprimé" || echo "  [--] Déjà inactif"

# -----------------------------------------------------------------------------
# 2. ACCESSIBILITY SERVICE
# -----------------------------------------------------------------------------
echo "[2/10] Désactivation du service d'accessibilité..."
settings put secure enabled_accessibility_services "" 2>/dev/null
pm disable-user --user 0 $PACKAGE_NAME/.AccessibilityService 2>/dev/null
am broadcast -a com.android.server.accessibility.ACTION_DISABLE_ACCESSIBILITY_SERVICE --es package $PACKAGE_NAME 2>/dev/null
echo "  [OK] Accessibility Service désactivé"

# -----------------------------------------------------------------------------
# 3. USAGE STATS
# -----------------------------------------------------------------------------
echo "[3/10] Révocation de l'autorisation Usage Stats..."
appops set $PACKAGE_NAME get_usage_stats ignore 2>/dev/null
echo "  [OK] Usage Stats révoqué"

# -----------------------------------------------------------------------------
# 4. BATTERY OPTIMIZATION
# -----------------------------------------------------------------------------
echo "[4/10] Réactivation de l'optimisation batterie..."
dumpsys battery reset 2>/dev/null
settings put global battery_optimization_mode auto 2>/dev/null
echo "  [OK] Optimisation batterie réactivée"

# -----------------------------------------------------------------------------
# 5. SMS PERMISSIONS
# -----------------------------------------------------------------------------
echo "[5/10] Révocation des permissions SMS..."
pm revoke $PACKAGE_NAME android.permission.READ_SMS 2>/dev/null
pm revoke $PACKAGE_NAME android.permission.SEND_SMS 2>/dev/null
pm revoke $PACKAGE_NAME android.permission.RECEIVE_SMS 2>/dev/null
echo "  [OK] Permissions SMS révoquées"

# -----------------------------------------------------------------------------
# 6. PHONE/CALL LOG PERMISSIONS
# -----------------------------------------------------------------------------
echo "[6/10] Révocation des permissions Téléphone..."
pm revoke $PACKAGE_NAME android.permission.READ_PHONE_STATE 2>/dev/null
pm revoke $PACKAGE_NAME android.permission.READ_CALL_LOG 2>/dev/null
pm revoke $PACKAGE_NAME android.permission.READ_CONTACTS 2>/dev/null
echo "  [OK] Permissions Téléphone révoquées"

# -----------------------------------------------------------------------------
# 7. LOCATION PERMISSIONS
# -----------------------------------------------------------------------------
echo "[7/10] Révocation des permissions Localisation..."
pm revoke $PACKAGE_NAME android.permission.ACCESS_FINE_LOCATION 2>/dev/null
pm revoke $PACKAGE_NAME android.permission.ACCESS_COARSE_LOCATION 2>/dev/null
echo "  [OK] Permissions Localisation révoquées"

# -----------------------------------------------------------------------------
# 8. CAMERA/MICROPHONE PERMISSIONS
# -----------------------------------------------------------------------------
echo "[8/10] Révocation des permissions Caméra et Microphone..."
pm revoke $PACKAGE_NAME android.permission.CAMERA 2>/dev/null
pm revoke $PACKAGE_NAME android.permission.RECORD_AUDIO 2>/dev/null
echo "  [OK] Permissions Caméra et Microphone révoquées"

# -----------------------------------------------------------------------------
# 9. STORAGE/NOTIFICATIONS PERMISSIONS
# -----------------------------------------------------------------------------
echo "[9/10] Révocation des permissions Stockage et Notifications..."
pm revoke $PACKAGE_NAME android.permission.READ_EXTERNAL_STORAGE 2>/dev/null
pm revoke $PACKAGE_NAME android.permission.WRITE_EXTERNAL_STORAGE 2>/dev/null
pm revoke $PACKAGE_NAME android.permission.POST_NOTIFICATIONS 2>/dev/null
echo "  [OK] Permissions Stockage et Notifications révoquées"

# -----------------------------------------------------------------------------
# 10. CACHE ET DONNÉES
# -----------------------------------------------------------------------------
echo "[10/10] Nettoyage du cache et des données..."
pm clear $PACKAGE_NAME 2>/dev/null
[ $? -eq 0 ] && echo "  [OK] Cache et données nettoyés" || echo "  [--] Nécessite permissions supplémentaires"

# -----------------------------------------------------------------------------
# RÉSUMÉ
# -----------------------------------------------------------------------------
echo ""
echo "========================================"
echo "RÉVOCATION TERMINÉE - 10/10"
echo "========================================"
echo ""
echo "Les 10 autorisations suivantes ont été révoquées:"
echo "  [1] Device Admin"
echo "  [2] Accessibility Service"
echo "  [3] Usage Stats"
echo "  [4] Battery Optimization"
echo "  [5] SMS (3 permissions)"
echo "  [6] Phone/Call Log (3 permissions)"
echo "  [7] Location (2 permissions)"
echo "  [8] Camera/Microphone (2 permissions)"
echo "  [9] Storage/Notifications (3 permissions)"
echo "  [10] Cache et données"
echo ""
echo "Vous pouvez maintenant redémarrer l'application"
echo "pour tester à nouveau le processus d'acquisition."
echo ""