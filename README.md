# LogistiScout

Gestion du matériel scout, des groupes, des événements et des contrôles.

## Fonctionnalités principales
- Authentification par groupe (ID + mot de passe)
- Gestion multi-groupes (chaque appareil peut se connecter à un groupe différent)
- Gestion des tentes (ajout, modification, suppression, historique de contrôles)
- Gestion des événements (rencontres, WE, camps) avec réservation de matériel
- Contrôle et checklist détaillée pour chaque tente
- Empêche la double réservation de tentes sur la même période
- Interface Flutter responsive

## Démarrage rapide

1. **Prérequis**
   - Flutter SDK installé ([voir la doc Flutter](https://docs.flutter.dev/get-started/install))
   - Un appareil ou un émulateur Android/iOS

2. **Installation des dépendances**
   ```bash
   flutter pub get
   ```

3. **Lancer l'application**
   ```bash
   flutter run
   ```

4. **Premier lancement**
   - L'application demande l'ID et le mot de passe du groupe scout (aucune vérification serveur par défaut, tout couple est accepté).
   - Ces identifiants sont mémorisés localement.

## Structure du projet
- `lib/` : code source principal (pages, modèles, helpers)
- `openapi.yaml` : documentation OpenAPI pour l'API serveur (à adapter selon vos besoins)
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` : plateformes supportées

## API serveur
Voir le fichier [`openapi.yaml`](openapi.yaml) pour la documentation complète des endpoints nécessaires à une synchronisation serveur.

## Personnalisation
- Pour ajouter une vérification réelle des identifiants groupe, il faut connecter l'app à un serveur conforme à l'OpenAPI fourni.
- Pour gérer plusieurs groupes sur un même appareil, il suffit de réinitialiser les identifiants dans les préférences locales.

## Contribution
Les PR et suggestions sont les bienvenues !

---
© 2024 LogistiScout

