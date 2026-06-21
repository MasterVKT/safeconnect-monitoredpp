# 📚 Guide de la Documentation XP SafeConnect

**Date**: 2025-12-31
**Version**: 1.0

---

## 🎯 Vue d'Ensemble

Ce dossier contient **toute la documentation nécessaire** pour développer les applications frontend (surveillante et surveillée) en intégration avec le backend XP SafeConnect.

---

## ⚠️ Important : Système Générique

**XP SafeConnect est un système de surveillance générique** qui peut être utilisé dans différents contextes légaux :

- 👨‍👩‍👧 **Contrôle parental** (parent → enfant)
- 💼 **Gestion professionnelle** (employeur → appareil professionnel)
- 👴 **Assistance médicale** (aidant → personne âgée)
- 🔒 **Autres cas légaux** avec consentement

**Le code backend et les endpoints utilisent une terminologie neutre** :
- `USER_TYPE='MONITOR'` = Utilisateur surveillant
- `USER_TYPE='MONITORED'` = Utilisateur surveillé

---

## 📄 Documents Disponibles

### 1️⃣ [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
**Type**: Documentation API générique
**Format**: Exemples curl, HTTP

**Contenu**:
- Description de tous les 67 endpoints implémentés
- Exemples de requêtes curl
- Codes d'erreur et gestion
- Webhooks My-CoolPay
- Rate limiting

**Utilisation**:
- ✅ Comprendre la structure de l'API
- ✅ Tester les endpoints manuellement
- ✅ Référence technique pour tous les endpoints

**Audience**: Développeurs backend/frontend, testeurs

---

### 2️⃣ [INTEGRATION_MONITORING_APP.md](INTEGRATION_MONITORING_APP.md) ⭐
**Type**: Guide d'intégration Flutter spécifique
**App**: Application Surveillante (MONITOR)

**Contenu** (~1300 lignes):
- Code Flutter/Dart complet prêt à l'emploi
- Architecture de l'app surveillante
- Authentification et gestion de compte
- Couplage d'appareils (scan QR, saisie code)
- Surveillance localisation + geofencing
- Monitoring communications (appels, messages)
- Surveillance médias et captures à distance
- Contrôle d'usage des applications
- Contrôle à distance (lock/unlock)
- Mode urgence
- Gestion abonnements (FREE/PREMIUM)
- State management avec Provider
- FCM pour notifications
- Gestion d'erreurs complète

**Utilisation**:
- ✅ **Guide principal pour développer l'app surveillante**
- ✅ Copier/coller le code Flutter
- ✅ Comprendre les flows utilisateur
- ✅ Intégration complète avec le backend

**Audience**: Développeur frontend (app surveillante), Agent AI

---

### 3️⃣ [INTEGRATION_MONITORED_APP.md](INTEGRATION_MONITORED_APP.md) ⭐
**Type**: Guide d'intégration Flutter spécifique
**App**: Application Surveillée (MONITORED)

**Contenu** (~2000 lignes):
- Code Flutter/Dart complet prêt à l'emploi
- Architecture de l'app surveillée
- Enregistrement avec `USER_TYPE='MONITORED'`
- Génération et affichage du code de couplage
- **Services en arrière-plan** :
  - Collecte localisation (toutes les 15 min)
  - Sync appels (toutes les heures)
  - Sync messages (toutes les heures)
  - Sync usage apps (toutes les 6 heures)
- **Gestion FCM** pour commandes à distance :
  - Capture photo/audio/screenshot
  - Verrouillage/déverrouillage
  - Rafraîchissement localisation
  - Synchronisation forcée
- Implémentation native Android (Kotlin)
- Bouton mode urgence
- Configuration complète permissions Android
- WorkManager pour tâches en arrière-plan

**Utilisation**:
- ✅ **Guide principal pour développer l'app surveillée**
- ✅ Copier/coller le code Flutter + Kotlin
- ✅ Comprendre les services en arrière-plan
- ✅ Gestion des permissions critiques
- ✅ Intégration complète avec le backend

**Audience**: Développeur frontend (app surveillée), Agent AI

---

### 4️⃣ [PLAN_DE_TESTS.md](PLAN_DE_TESTS.md)
**Type**: Stratégie de tests

**Contenu**:
- Plan de tests complet pour le backend
- Fixtures pytest
- Cas de tests pour chaque module
- Objectif de couverture >80%

**Utilisation**:
- ✅ Comprendre la stratégie de tests
- ✅ Écrire des tests supplémentaires

**Audience**: Développeurs backend, QA

---

## 🔄 Quelle Documentation Utiliser ?

### Pour développer l'**Application Surveillante** (MONITOR):

1. **Lire** [INTEGRATION_MONITORING_APP.md](INTEGRATION_MONITORING_APP.md) ← **PRINCIPAL**
2. **Référence** [API_DOCUMENTATION.md](API_DOCUMENTATION.md) si besoin de détails sur un endpoint

### Pour développer l'**Application Surveillée** (MONITORED):

1. **Lire** [INTEGRATION_MONITORED_APP.md](INTEGRATION_MONITORED_APP.md) ← **PRINCIPAL**
2. **Référence** [API_DOCUMENTATION.md](API_DOCUMENTATION.md) si besoin de détails sur un endpoint

### Pour tester l'API manuellement:

1. **Utiliser** [API_DOCUMENTATION.md](API_DOCUMENTATION.md) avec curl/Postman
2. **Ou** utiliser Swagger UI à `http://localhost:8000/swagger/`

---

## 🤖 Guide pour Agent AI Développeur Frontend

Si vous êtes un **Agent AI** chargé de développer les applications Flutter :

### Étape 1 : Comprendre le Contexte
- ✅ Lire cette page (README_DOCUMENTATION.md)
- ✅ Comprendre que le système est **générique** (pas uniquement parent-enfant)
- ✅ Utiliser la terminologie **USER_TYPE='MONITOR'** et **USER_TYPE='MONITORED'**

### Étape 2 : Développer l'App Surveillante
- ✅ Ouvrir [INTEGRATION_MONITORING_APP.md](INTEGRATION_MONITORING_APP.md)
- ✅ Suivre le guide section par section
- ✅ Copier/adapter le code Flutter fourni
- ✅ Implémenter tous les endpoints listés
- ✅ Tester avec le backend à `http://localhost:8000`

### Étape 3 : Développer l'App Surveillée
- ✅ Ouvrir [INTEGRATION_MONITORED_APP.md](INTEGRATION_MONITORED_APP.md)
- ✅ Suivre le guide section par section
- ✅ Copier/adapter le code Flutter + Kotlin fourni
- ✅ Configurer les **services en arrière-plan** (WorkManager)
- ✅ Configurer les **permissions Android** complètes
- ✅ Implémenter le **handler FCM** pour commandes
- ✅ Tester avec le backend à `http://localhost:8000`

### Étape 4 : Tester l'Intégration Complète
- ✅ App Surveillante : Créer compte MONITOR
- ✅ App Surveillée : Créer compte MONITORED
- ✅ App Surveillée : Générer code de couplage
- ✅ App Surveillante : Scanner/saisir le code
- ✅ Tester tous les flows (localisation, appels, messages, captures, urgence)

---

## 📊 Récapitulatif des Endpoints (67 total)

| Catégorie | Endpoints | Status | Utilisé par |
|-----------|-----------|--------|-------------|
| Authentification | 11/11 | ✅ 100% | Les 2 apps |
| Appareils | 11/11 | ✅ 100% | Les 2 apps |
| Localisation | 6/6 | ✅ 100% | Les 2 apps |
| Messages | 4/4 | ✅ 100% | App Surveillée (collecte) + App Surveillante (consultation) |
| Appels | 3/3 | ✅ 100% | App Surveillée (collecte) + App Surveillante (consultation) |
| Médias | 7/7 | ✅ 100% | Les 2 apps |
| Usage Apps | 7/7 | ✅ 100% | App Surveillée (collecte) + App Surveillante (consultation) |
| Paramètres User | 7/7 | ✅ 100% | App Surveillante principalement |
| Urgence | 6/6 | ✅ 100% | Les 2 apps |
| Abonnement | 5/5 | ✅ 100% | App Surveillante |

Voir [CONFORMITE_ENDPOINTS.md](../CONFORMITE_ENDPOINTS.md) pour le détail complet.

---

## 🔑 Concepts Clés

### USER_TYPE
- **'MONITOR'** : Utilisateur surveillant (possède l'app surveillante)
- **'MONITORED'** : Utilisateur surveillé (possède l'app surveillée)

### Device Pairing
1. App surveillée génère un code unique (6 caractères, valable 10 min)
2. App surveillante scanne QR ou saisit le code
3. Backend crée une `DevicePermission` reliant les deux appareils

### Premium vs FREE
- **FREE** : 1 appareil, captures limitées, historique 7 jours
- **PREMIUM** : 10 appareils, captures illimitées, historique illimité, geofencing, blocage apps

### Firebase Cloud Messaging (FCM)
- App surveillante : Reçoit notifications simples
- App surveillée : **Reçoit et exécute des commandes** (capture, lock, sync)

### Services en Arrière-Plan (App Surveillée)
- **WorkManager** pour tâches périodiques
- Collecte automatique même quand l'app est fermée
- Nécessite permissions Android étendues

---

## 📞 Support

- **Email**: support@xpsafeconnect.com
- **Backend API**: `http://localhost:8000` (dev) | `https://api.xpsafeconnect.com` (prod)
- **Swagger**: `http://localhost:8000/swagger/`

---

## 📄 License

Propriétaire - XP SafeConnect © 2025

---

**Bonne intégration! 🚀**
