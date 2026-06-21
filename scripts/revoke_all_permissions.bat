@echo off
setlocal enabledelayedexpansion
REM =============================================================================
REM Script de revocation de TOUTES les autorisations XP SafeConnect Monitored App
REM =============================================================================
REM Ce script supprime toutes les autorisations accordees a l'application surveilee
REM (10 autorisations principales) pour permettre de tester a nouveau
REM le processus d'acquisition des permissions.
REM
REM Usage: Double-cliquez sur ce fichier ou executez dans le terminal:
REM   revoke_all_permissions.bat
REM
REM Prerequisites: ADB installe et appareil connecte en mode debug USB
REM =============================================================================

set PACKAGE_NAME=com.xpsafeconnect.monitored_app

echo.
echo ========================================
echo XP SafeConnect - Revocation des autorisations
echo ========================================
echo.
echo Package: %PACKAGE_NAME%
echo.

REM Verifier que ADB est disponible
adb version >nul 2>&1
if errorlevel 1 (
    echo ERREUR: ADB n'est pas reconnu. Verifiez votre installation ADB.
    echo   - ADB doit etre dans le PATH systeme.
    echo   - Telechargez Android Platform Tools si necessaire.
    pause
    exit /b 1
)

REM Demarrer le serveur ADB si necessaire (evite les faux negatifs)
adb start-server >nul 2>&1

REM Afficher l'etat des appareils pour diagnostic
echo Detection des appareils connectes...
adb devices
echo.

REM Verifier qu'un appareil autorise est connecte
REM   findstr /r " device$" detecte les lignes SERIAL<espace>device (appareils autorises)
REM   "device" seul en fin de ligne exclut l'en-tete "List of devices attached"
set DEVICE_FOUND=0
set UNAUTHORIZED_FOUND=0

adb devices 2>nul | findstr /r " device$" >nul 2>&1
if not errorlevel 1 set DEVICE_FOUND=1

adb devices 2>nul | findstr "unauthorized" >nul 2>&1
if not errorlevel 1 set UNAUTHORIZED_FOUND=1

if "%DEVICE_FOUND%"=="0" (
    if "%UNAUTHORIZED_FOUND%"=="1" (
        echo ERREUR: Appareil detecte mais non autorise.
        echo.
        echo Solutions :
        echo   1. Regardez l'ecran de votre appareil Android.
        echo   2. Appuyez sur "Autoriser" dans la boite de dialogue debogage USB.
        echo   3. Cochez "Toujours autoriser depuis cet ordinateur" pour eviter ce probleme.
    ) else (
        echo ERREUR: Aucun appareil connecte ou reconnu.
        echo.
        echo Solutions :
        echo   1. Verifiez le cable USB ^(essayez un autre cable ou port^).
        echo   2. Activez le mode developpeur : Parametres ^> A propos ^> appuyez 7x sur Numero de build.
        echo   3. Activez le debogage USB : Parametres ^> Options developpeur ^> Debogage USB.
        echo   4. Executez "adb kill-server" dans un terminal puis relancez ce script.
    )
    pause
    exit /b 1
)

REM =============================================================================
REM SELECTION DE L'APPAREIL CIBLE
REM Si plusieurs appareils sont connectes, selectionner le premier appareil
REM physique (non-emulateur). L'emulateur commence par "emulator-".
REM =============================================================================
set DEVICE_SERIAL=
set PHYSICAL_SERIAL=
set EMULATOR_SERIAL=

for /f "tokens=1,2" %%a in ('adb devices 2^>nul') do (
    if /i "%%b"=="device" (
        echo %%a | findstr /i "emulator" >nul 2>&1
        if errorlevel 1 (
            REM C'est un appareil physique
            if "!PHYSICAL_SERIAL!"=="" set PHYSICAL_SERIAL=%%a
        ) else (
            REM C'est un emulateur
            if "!EMULATOR_SERIAL!"=="" set EMULATOR_SERIAL=%%a
        )
    )
)

REM Preferer l'appareil physique, sinon l'emulateur
if not "!PHYSICAL_SERIAL!"=="" (
    set DEVICE_SERIAL=!PHYSICAL_SERIAL!
    echo Appareil physique selectionne : !PHYSICAL_SERIAL!
) else (
    set DEVICE_SERIAL=!EMULATOR_SERIAL!
    echo Emulateur selectionne : !EMULATOR_SERIAL!
)
echo.

REM Raccourci : toutes les commandes adb utiliseront -s %DEVICE_SERIAL%
set ADB=adb -s %DEVICE_SERIAL%

REM =============================================================================
REM REVOCATION DES PERMISSIONS
REM NOTE: "pm clear" (etape finale) efface donnees + TOUTES les permissions.
REM Les etapes 1-9 revoquer d'abord les permissions speciales qui ne sont pas
REM couvertes ou necessitent un ordre precis (ex: device admin avant pm clear).
REM =============================================================================

echo [1/10] Suppression du Device Admin...
REM =============================================================================
REM 1. DEVICE ADMIN
REM  dpm remove-active-admin necessite le nom complet du composant.
REM =============================================================================
%ADB% shell dpm remove-active-admin %PACKAGE_NAME%/.AntiUninstallAdmin
if %errorlevel% equ 0 (
    echo   [OK] Device Admin supprime
) else (
    echo   [--] Deja inactif ^(normal si jamais accorde^)
)

echo.
echo [2/10] Revocation du service d'accessibilite...
REM =============================================================================
REM 2. ACCESSIBILITY SERVICE
REM  Vider la liste des services actives suffit a desactiver tous d'un coup.
REM =============================================================================
%ADB% shell settings put secure enabled_accessibility_services ""
echo   [OK] Accessibility Service revoque

echo.
echo [3/10] Revocation de l'autorisation Usage Stats...
REM =============================================================================
REM 3. USAGE STATS
REM  appops "ignore" revoque l'acces aux statistiques d'utilisation.
REM =============================================================================
%ADB% shell appops set %PACKAGE_NAME% GET_USAGE_STATS default
echo   [OK] Usage Stats revoque

echo.
echo [4/10] Reactivation de l'optimisation batterie...
REM =============================================================================
REM 4. BATTERY OPTIMIZATION
REM  Retirer le package de la whitelist "ignore battery optimization".
REM =============================================================================
%ADB% shell dumpsys deviceidle whitelist -%PACKAGE_NAME%
echo   [OK] Optimisation batterie reactive

echo.
echo [5/10] Arret force de l'application...
REM =============================================================================
REM 5. FORCE-STOP
REM  Necessaire avant pm clear pour eviter les erreurs "app is device admin".
REM =============================================================================
%ADB% shell am force-stop %PACKAGE_NAME%
echo   [OK] Application stoppee

echo.
echo [6/10] Nettoyage complet ^(donnees + cache + toutes les permissions^)...
REM =============================================================================
REM 6. PM CLEAR
REM  Efface l'integralite des donnees de l'app : SharedPreferences, base SQLite,
REM  cache, ET revoque toutes les permissions runtime en une seule commande.
REM  C'est la commande la plus efficace - equivalent a une reinstallation propre
REM  sans desinstaller l'APK.
REM =============================================================================
%ADB% shell pm clear %PACKAGE_NAME%
if %errorlevel% equ 0 (
    echo   [OK] Donnees, cache et permissions runtime effaces
) else (
    echo   [ERREUR] pm clear a echoue. L'application est peut-etre encore admin.
    echo            Verifiez manuellement : Parametres ^> Securite ^> Admin appareil
    echo            Desactivez l'app puis relancez ce script.
)

echo.
echo [7-10/10] Revocation individuelle des permissions runtime...
REM =============================================================================
REM 7-10. PERMISSIONS RUNTIME INDIVIDUELLES
REM  Ces commandes sont redondantes si pm clear a reussi, mais servent de
REM  filet de securite si pm clear a echoue pour une raison quelconque.
REM =============================================================================
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.READ_SMS >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.SEND_SMS >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.RECEIVE_SMS >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.READ_PHONE_STATE >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.READ_CALL_LOG >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.READ_CONTACTS >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.ACCESS_FINE_LOCATION >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.ACCESS_COARSE_LOCATION >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.ACCESS_BACKGROUND_LOCATION >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.CAMERA >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.RECORD_AUDIO >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.READ_EXTERNAL_STORAGE >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.WRITE_EXTERNAL_STORAGE >nul 2>&1
%ADB% shell pm revoke %PACKAGE_NAME% android.permission.POST_NOTIFICATIONS >nul 2>&1
echo   [OK] Permissions runtime revoquees

echo.
echo ========================================
echo REVOCATION TERMINEE
echo ========================================
echo.
echo Appareil cible : %DEVICE_SERIAL%
echo Package        : %PACKAGE_NAME%
echo.
echo Autorisations revoquees :
echo   [1] Device Admin ^(dpm^)
echo   [2] Accessibility Service
echo   [3] Usage Stats ^(appops^)
echo   [4] Battery Optimization ^(whitelist^)
echo   [5] Arret force
echo   [6] pm clear ^(donnees + cache + toutes permissions^)
echo   [7-10] Permissions runtime individuelles ^(filet de securite^)
echo.
echo ACTIONS MANUELLES SI NECESSAIRE:
echo   - Si Device Admin encore actif :
echo     Parametres ^> Securite ^> Admins appareil ^> Desactiver XP SafeConnect
echo   - Si Accessibilite encore active :
echo     Parametres ^> Accessibilite ^> Services installes ^> Desactiver
echo.
echo Vous pouvez maintenant relancer l'application pour
echo tester a nouveau le processus d'acquisition des permissions.
echo.
pause