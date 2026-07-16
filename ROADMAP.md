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
- Incohérence Dashboard « Aucune portée active » vs onglet Portées « Portée de Salsa » : mélange mock/serveur résiduel dans DashboardViewModel/LittersViewModel à investiguer (la persistance backend F03 est OK)
