# TODO — logistiscout (Flutter mobile)

Remarques issues d'une revue de code senior (2026-06-20).

---

## Critique

- [ ] **Bug URL `getEventListByPeriod`** (`lib/services/api_service.dart:471`)
  ```dart
  '/evenements&debut=${start.toIso8601String()}...'  // ❌ & au lieu de ?
  ```
  Le premier paramètre de query string doit commencer par `?`, pas `&`.
  Cette méthode est actuellement cassée.

- [ ] **Bug `updateMenu`** (`lib/services/api_service.dart:637`)
  ```dart
  HttpMethod.put, '/menus',  // ❌ l'ID est absent de l'URL
  ```
  Doit être `/menus/$menuId`. La requête atterrit sur le mauvais endpoint.

- [ ] **Bypass du DI dans `TentesController`** (`lib/ui/controllers/tentes_controller.dart:13`)
  ```dart
  final TentRepository _repo = TentRepositoryImpl(ApiService());
  ```
  Instancie `ApiService()` directement au lieu de passer par Riverpod
  (`ref.read(tentRepositoryProvider)`). Casse le DI et rend les tests impossibles.
  Vérifier si d'autres controllers font pareil.

---

## Important

- [ ] **`AuthService` et Dio morts** (`lib/services/auth_service.dart`)
  `AuthService` utilise Dio mais n'est référencé nulle part dans l'app.
  Résultat : deux librairies HTTP dans le bundle (http + dio) pour rien.
  Supprimer `auth_service.dart` et retirer `dio` de `pubspec.yaml`.

- [ ] **`403` traité comme expiration de session** (`lib/services/api_service.dart:132`)
  ```dart
  final isAuthError = response.statusCode == 401 || response.statusCode == 403;
  ```
  Un 403 (Forbidden) n'est pas un token expiré. Peut provoquer un refresh inutile
  et une déconnexion surprise. Traiter 401 et 403 séparément.

- [ ] **Tests commentés dans le CI** (`.github/workflows/deploy-playstore.yml:9-32`)
  Le job `flutter_test` est entièrement commenté. Le pipeline déploie sur Play Store
  sans aucune validation automatique. Réactiver ou remplacer par `flutter analyze`
  + `flutter test` a minima.

- [ ] **`qr_flutter` depuis git sans commit épinglé** (`pubspec.yaml:58-61`)
  ```yaml
  qr_flutter:
    git:
      url: https://github.com/theyakka/qr.flutter.git
  ```
  Build non-reproductible si le repo change ou disparaît. Épingler un `ref: <sha>`
  ou utiliser la version pub.dev si disponible.

---

## Mineur

- [ ] **`build_release.zip` tracké dans git**
  Artifact binaire dans le repo = anti-pattern. Supprimer du repo et ajouter
  `*.zip` au `.gitignore`.

- [ ] **`addMenu` et `createMenu` dupliqués** (`lib/services/api_service.dart:632,675`)
  Les deux méthodes font un `POST /menus` avec le même payload. L'une est inutile.
