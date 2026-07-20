# ROADMAP — Idées hors scope V1

> **Règle** : toute idée hors F01-F10 → 1 ligne ici, zéro discussion dans la session courante. Revue post-build.

## Post-V1

- Généalogie graphique (arbre de parité visuel)
- Multi-utilisateur sur un même élevage
- Transfert de carnet entre éleveurs
- Mode propriétaire (vue acheteur de son chiot)
- Comptabilité (suivi des revenus de cession)
- Intégrations API externes (SCC, LOF, LOOF)
- Web app
- Multi-élevage par compte
- Multi-espèces dans un même élevage (un Kennel gère chiens + chats)
- Export courbe de croissance (PNG/PDF)
- Synchronisation offline résiliente
- Fiche d'accompagnement chiot (PDF : courbe de croissance + historique soins)
- Upload photo reproducteur/chiot (image_picker, actuellement photoUrl = URL manuelle)
- UI dédiée de clôture manuelle de portée (updateLitter isActive=false existe côté backend, écran à faire)
- Dashboard : chiots et rappels encore alimentés par MockPuppyRepository/MockCareRepository (F04+). Le nom de la mère est désormais résolu réellement (fix F03).
- F04 chiots : backend puppy + ServerpodPuppyRepository à créer. Bug actuel : createPuppiesBatch fait toujours des add (jamais d'update) → duplication à chaque sauvegarde ; loadLitterPuppies pré-remplit 3 chiots mockers ; rien n'est persisté (mock en mémoire).
- Lenteur perceptible sur mobile (à profiler : startup, appels serveur, rebuilds).
- Date picker de date de naissance en anglais (i18n / localization FR à configurer).
- Suppression de compte : KO (SnackBar seul, pas d'action réelle). → **F10-B** (RGPD : suppression compte + export + anonymisation, hors F10-A).
- « Ajouter mes reproducteurs d'abord » persiste sur l'accueil après ajout de reproducteurs (cohérence d'état Dashboard à revoir).
- **Entitlement lifetime (accès à vie offert)** : F10-A traite un `expiration_date` nul côté RevenueCat comme non-premium (règle V1 documentée dans `PremiumSyncService`). Revoir cette règle quand le plan d'acquisition introduit un entitlement à vie — il faudra distinguer « pas de date = illimité premium » de « pas de date = pas d'abo ».
