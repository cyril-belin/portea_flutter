# F10 — Premium (RevenueCat + Réglages + RGPD)

## Objectif

Intégrer RevenueCat (SDK purchases_flutter) pour la gestion des abonnements, afficher le paywall aux 3 points de déclenchement, permettre la restauration des achats, gérer les réglages de l'élevage et la suppression de compte RGPD.

---

## État actuel (audit 2026-07-15)

### Fait ✅
- `PorteaPremiumScreen` — UI complète : avantages, toggle annuel/mensuel, prix affichés (hardcodés), bouton "Test" qui toggle `isPremium`
- `SettingsScreen` — réglages élevage (nom, affixe, SIRET, propriétaire), thème (clair/sombre/système)
- `SettingsViewModel` — `loadSettings()`, `updateKennel()`, `updateThemeMode()`, `togglePremium()` (mock)
- `ISettingsRepository` — `isPremium()`, `setPremium()`, `getThemeMode()`, `setThemeMode()`
- `MockSettingsRepository` — in-memory (bool `premiumUser`)
- 3 déclencheurs paywall codés :
  - Génération document → `DocumentsScreen` (F09)
  - 2e portée active → `LittersHistoryScreen` / `LitterDeclarationViewModel`
  - Historique verrouillé → `LittersHistoryScreen`
- Route `/premium`
- Tests unitaires `SettingsViewModel` passing

### Absent ❌
- **`purchases_flutter`** : absent du pubspec
- **RevenueCat SDK** : aucune intégration — aucun appel `Purchases.*`
- **Prix dynamiques** : hardcodés (89,99€/an, 9,99€/mois). Doivent venir des offerings RevenueCat.
- **`appUserID`** : non configuré (= ID utilisateur Serverpod)
- **Webhook RevenueCat → Serverpod** : absent — modèle `Kennel.premiumJusquAu: DateTime?` absent
- **Restaurer les achats** : bouton présent (`TextButton 'Restaurer mes achats'`) mais pas câblé
- **Suppression compte RGPD** : absent de `SettingsScreen` et du backend
- **`ServerpodSettingsRepository`** : absent (premium est un bool in-memory)

---

## Reste à faire

### Modèle Kennel (backend)
- [ ] Ajouter `premiumUntil: DateTime?` au modèle YAML `Kennel` (côté serveur)
- [ ] `isPremium()` côté serveur = `kennel.premiumUntil != null && kennel.premiumUntil!.isAfter(DateTime.now())`
- [ ] `serverpod generate` → `portea_client` mis à jour
- [ ] Endpoint webhook : `POST /webhooks/revenuecat` — vérifie la signature RevenueCat, met à jour `kennel.premiumUntil`

### Package & Configuration RevenueCat
- [ ] Ajouter `purchases_flutter: ^7.x` au pubspec
- [ ] Configurer App Store Connect : produits in-app (mensuel + annuel), entitlements `premium`
- [ ] Configurer Google Play Console : idem
- [ ] Clé API RevenueCat (Android + iOS) → stocker dans `assets/config.json` (déjà présent) ou variables d'env build

### PremiumService
- [ ] Créer `lib/core/services/premium_service.dart` :
  - `initialize(String appUserId)` — `Purchases.configure(PurchasesConfiguration(apiKey)..appUserID = appUserId)`
  - `getOfferings()` → `Future<Offerings>` — pour afficher les prix dynamiques
  - `purchase(Package package)` → `Future<CustomerInfo>`
  - `restorePurchases()` → `Future<CustomerInfo>`
  - `checkEntitlement()` → `bool` (local, cache RevenueCat)

### SettingsRepository
- [ ] `ServerpodSettingsRepository implements ISettingsRepository` :
  - `isPremium()` : appelle `client.kennel.isPremium()` (ou lit `kennel.premiumUntil`)
  - `setPremium(bool)` : INTERDIT côté client — c'est le webhook RevenueCat qui met à jour. Laisser la méthode pour les tests.
  - `getThemeMode()` / `setThemeMode()` : via `SharedPreferences` (local, pas de serveur)
- [ ] Swapper `MockSettingsRepository` → `ServerpodSettingsRepository` dans `main.dart`

### UI — PorteaPremiumScreen
- [ ] Supprimer les prix hardcodés → charger depuis `PremiumService.getOfferings()`
- [ ] Remplacer le bouton "Test" par `PremiumService.purchase(package)` + gestion erreur
- [ ] Câbler "Restaurer mes achats" → `PremiumService.restorePurchases()`
- [ ] Après achat/restauration → `SettingsViewModel.loadSettings()` pour rafraîchir l'état

### UI — SettingsScreen (RGPD)
- [ ] Ajouter section "Mon compte" avec bouton "Supprimer mon compte"
- [ ] Dialog de confirmation RGPD → appel `client.auth.deleteAccount(session)` (à vérifier dans Serverpod v4 auth API)
- [ ] Après suppression : déconnexion + redirect `/onboarding/welcome`

### AppUserID
- [ ] Au login (F01), récupérer l'ID utilisateur Serverpod et appeler `PremiumService.initialize(userId.toString())`

---

## Écrans concernés

| Écran | Fichier | État |
|-------|---------|------|
| Paywall | `settings/presentation/screens/portea_premium_screen.dart` | ⚠️ Stub |
| Réglages | `settings/presentation/screens/settings_screen.dart` | ✅ Fait (RGPD absent) |

---

## Architecture premium (décision G3)

```
RevenueCat SDK (client)
  ↓ achat
RevenueCat webhook POST → portea_server/webhooks/revenuecat
  ↓ vérifie signature + met à jour
Kennel.premiumUntil: DateTime?
  ↓ lu par
ServerpodSettingsRepository.isPremium()
  ↓ lu par
SettingsViewModel.isPremium
  ↓ contrôle
PorteaPremiumScreen / DocumentsScreen / LittersHistoryScreen
```

**Règle** : jamais de `isPremium = true` écrit depuis le client. Uniquement depuis le webhook serveur.

---

## Règles métier

1. Premium = `Kennel.premiumUntil != null && premiumUntil.isAfter(now())`. Jamais un bool.
2. 3 déclencheurs paywall :
   - Tentative de génération de document PDF (F09)
   - Tentative de création d'une 2e portée active (F03)
   - Accès à l'historique des portées passées (F03)
3. Prix affichés = offerings RevenueCat (jamais hardcodés).
4. `appUserID` RevenueCat = ID Serverpod de l'utilisateur (configuré au login).
5. Suppression de compte : RGPD — toutes les données du kennel (portées, chiots, soins) doivent être supprimées en cascade.

---

## Critères d'acceptation

- [ ] Achat premium en sandbox → `premiumUntil` mis à jour sur le serveur via webhook.
- [ ] Prix affichés dans `PorteaPremiumScreen` = offerings RevenueCat (pas hardcodés).
- [ ] "Restaurer mes achats" fonctionne.
- [ ] Suppression de compte → données supprimées + déconnexion.
- [ ] `dart analyze` 0 warning.
- [ ] `flutter test` vert sur `SettingsViewModel` tests.
