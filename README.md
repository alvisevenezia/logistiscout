# LogistiScout

Gestion du matériel scout, des groupes, des événements et des contrôles.

## Fonctionnalités principales
- Authentification par groupe (ID + mot de passe)
- Gestion multi-groupes (chaque appareil peut se connecter à un groupe différent)
- Gestion des tentes (ajout, modification, suppression, historique de contrôles)
- Gestion des événements (rencontres, WE, camps) avec réservation de matériel
- Contrôle et checklist détaillée pour chaque tente
- Empêche la double réservation de tentes sur la même période

## Démarrage rapide

1. **Prérequis**
   - Flutter SDK installé ([voir la doc Flutter](https://docs.flutter.dev/get-started/install))
   - Android Studio avec les extensions Flutter et Dart

2. **Installation des dépendances**
   ```bash
   flutter pub get
   ```

3. **Lancer l'application**
   ```bash
   flutter run
   ```

4. **Premier lancement**
   - L'application demande l'ID et le mot de passe du groupe scout.
   - Ces identifiants sont mémorisés localement.

## Structure du projet
- `lib/` : code source principal (pages, modèles, helpers)
- `openapi.yaml` : documentation OpenAPI pour l'API serveur (à adapter selon vos besoins)
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` : plateformes supportées

## API serveur
Voir le fichier [`openapi.yaml`](openapi.yaml) pour la documentation des endpoints 

## Contribution
Les PR et suggestions sont les bienvenues !

---
© 2024 LogistiScout

