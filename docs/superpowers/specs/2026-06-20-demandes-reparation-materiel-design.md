# Demandes de réparation de matériel — Design

Date : 2026-06-20
Statut : Approuvé (en attente du plan d'implémentation)

## Contexte

Aujourd'hui, le seul "matériel" suivi dans l'app est la tente (`Tent`), avec un état
de base (`TentState` : `good` / `repair` / `broken` / `lost`) et un statut custom
optionnel par groupe (`tentStatusId`/`tentStatusLabel`/`tentStatusColor`). Il n'existe
aucun suivi structuré des problèmes rencontrés : passer une tente en "À réparer" ne
dit rien sur *quoi* est cassé, *qui* l'a signalé, ni si quelqu'un s'en occupe déjà.

Ce design introduit une entité `RepairRequest` (demande de réparation), liée à une
tente, avec un cycle de vie simple. Portée volontairement limitée aux tentes pour
l'instant — l'app n'a pas encore de notion de matériel générique (popotes, tables,
outils...), et ce périmètre sera traité comme un projet séparé le jour venu.

## Hors périmètre

- Matériel générique (hors tentes) — extension future, pas traitée ici.
- Assignation d'une demande à une personne précise — pas de système de rôles dans
  l'app aujourd'hui, on reste simple.
- Nouvel onglet de navigation principale dédié — la bottom nav a déjà 4 entrées
  (Accueil/Tentes/Événements/Contact), on ne la surcharge pas pour cette feature.

## Modèle de données

### Backend (`logistiscout_back`)

Nouvelle table dans `app/models.py`, suivant le style de `Controle` (pas de
migration Alembic dans ce projet — les tables sont créées via
`Base.metadata.create_all` au démarrage, donc l'ajout est sans risque) :

```python
class RepairRequest(Base):
    __tablename__ = "repair_requests"
    id = Column(Integer, primary_key=True, index=True)
    tentId = Column(Integer, ForeignKey("tentes.id"), index=True, nullable=False)
    controlId = Column(Integer, ForeignKey("controles.id"), index=True, nullable=True)
    description = Column(Text, nullable=False)
    imageUrls = Column(ARRAY(String), default=list)
    status = Column(String, default="open")  # open | in_progress | resolved
    createdByUserId = Column(Integer, nullable=False)
    createdAt = Column(DateTime, nullable=False)
    resolvedAt = Column(DateTime, nullable=True)
    resolvedComment = Column(Text, nullable=True)
```

Pas de `groupeId` dénormalisé : le scoping par groupe se fait par jointure sur
`tentes`, exactement comme `list_controles` le fait déjà dans
`app/routes/v2/controls_v2.py`.

Schemas Pydantic dans `app/schemas.py`, suivant le pattern `ControleBase` /
`ControleCreate` / `Controle` :

```python
class RepairRequestBase(BaseModel):
    tentId: int
    controlId: Optional[int] = None
    description: str
    imageUrls: List[str] = Field(default_factory=list)
    status: str = "open"

class RepairRequestCreate(RepairRequestBase):
    pass

class RepairRequestUpdate(BaseModel):
    status: Optional[str] = None
    resolvedComment: Optional[str] = None

class RepairRequest(RepairRequestBase):
    id: int
    createdByUserId: int
    createdAt: datetime
    resolvedAt: Optional[datetime] = None
    resolvedComment: Optional[str] = None
    class Config:
        from_attributes = True
```

### Flutter (`logistiscout`)

`lib/domain/entities/repair_request.dart` — entité immuable + `copyWith`, sur le
modèle de `Control` (`lib/domain/entities/controle.dart`) :

```dart
enum RepairRequestStatus { open, inProgress, resolved }

class RepairRequest {
  final int? id;
  final int tentId;
  final int? controlId;
  final String description;
  final List<String> imageUrls;
  final RepairRequestStatus status;
  final int createdByUserId;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedComment;
  // copyWith, fromJson, toJson — mêmes conventions que Control.
}
```

`lib/data/models/repair_request_dto.dart` si le projet garde la séparation
DTO/entité comme pour `tente_dto.dart` / `controle_dto.dart` (à confirmer en
regardant le mapper existant pendant l'implémentation — sinon JSON direct dans
l'entité comme le fait déjà `Control`).

## API

Nouveau fichier `app/routes/v2/repair_requests_v2.py`, monté sur le même routeur
v2, scoping groupe via `get_current_groupe` + jointure sur `Tente` :

- `GET /v2/repair_requests?tentId=&status=` — liste, filtrable par tente et/ou statut
- `POST /v2/repair_requests` — création
- `PATCH /v2/repair_requests/{id}` — changement de statut / `resolvedComment`
- `DELETE /v2/repair_requests/{id}` — suppression (erreur de signalement)

Côté Flutter, dans `lib/services/api_service.dart`, suivant le pattern
`createTent`/`updateTent`/`deleteTent` :

```dart
Future<List<dynamic>> getRepairRequests({int? tentId, String? status});
Future<Map<String, dynamic>> createRepairRequest(Map<String, dynamic> body);
Future<void> updateRepairRequest(int id, Map<String, dynamic> body);
Future<void> deleteRepairRequest(int id);
```

## Synchronisation avec l'état de la tente

Logique centralisée côté backend (dans les routes `repair_requests_v2.py`, pas
dupliquée côté Flutter) :

- **Création** (`status=open`) : si `tente.etat` est `good`, passer à `repair`.
  Ne jamais écraser `broken` ou `lost` (états plus graves/définitifs) avec une
  simple demande de réparation.
- **Résolution** (`status` passe à `resolved`) : si c'était la **dernière**
  demande `open`/`in_progress` restante pour cette tente, et que `tente.etat`
  vaut toujours `repair`, repasser à `good`. Sinon ne rien changer (soit il
  reste d'autres demandes ouvertes, soit quelqu'un a changé l'état manuellement
  entre-temps).
- Cette règle agit uniquement sur le champ de base `etat`/`state`, jamais sur le
  statut custom `tentStatusId` (système de statuts personnalisés par groupe),
  qui reste géré manuellement comme aujourd'hui.

## Points de création

Les deux confirmés :

1. **Depuis un contrôle** (`lib/ui/pages/control/controle_edit_page.dart`) : à la
   sauvegarde, si au moins un élément du checklist est `StatusElementControl.ko`,
   afficher un dialogue "X élément(s) en panne détecté(s) — créer une demande de
   réparation ?". Si confirmé : une seule `RepairRequest`, `controlId` renseigné,
   `description` générée depuis les libellés des éléments KO + le commentaire du
   contrôle, `imageUrls` reprises du contrôle.
2. **Manuelle** (`lib/ui/pages/tent/tente_detail_page.dart`) : bouton "Signaler un
   problème" ouvrant un formulaire (description obligatoire, photos optionnelles
   via le picker déjà utilisé pour les contrôles) → `RepairRequest` sans
   `controlId`.

## UI

- **Fiche tente** (`tente_detail_page.dart`) : nouvelle section "Réparations" —
  demandes `open`/`in_progress` en avant avec actions ("Prendre en charge" →
  `in_progress`, "Marquer résolu" → `resolved`, avec champ `resolvedComment`
  optionnel), demandes `resolved` repliées dans un historique (même logique
  d'affichage que `controlHistory`).
- **Vue globale** : bandeau/bouton "Réparations en cours (N)" en haut de
  `tentes_page.dart`, menant à une nouvelle route `/tents/repairs` (déclarée dans
  `lib/main.dart` sous la branche `/tents`) listant toutes les demandes
  `open`/`in_progress` du groupe, triées par date de création, tap → fiche tente
  concernée.

## Gestion d'erreurs

- Pas de description vide à la création (validation côté formulaire, comme les
  autres formulaires de l'app).
- Échec réseau à la création/changement de statut : message d'erreur via le
  pattern `ScaffoldMessenger` déjà utilisé ailleurs (ex. `home_page.dart`), pas
  de retry automatique.
- Suppression d'une tente : envisager `ondelete="CASCADE"` ou suppression
  applicative des `repair_requests` associées pour éviter des lignes orphelines
  (à trancher pendant l'implémentation selon ce qui existe déjà pour `controles`
  à la suppression d'une tente).

## Tests

- **Backend** : tests sur les nouvelles routes suivant le pattern
  `app/tests/test_app.py` (`DummyDb` + `monkeypatch`), + tests dédiés à la
  logique de synchronisation d'état de tente (dernière demande résolue avec et
  sans demandes restantes, tente déjà `broken`/`lost` au moment de la création).
- **Flutter** : tests unitaires sur le repository/controller (mock
  `ApiService`, pattern Riverpod existant) ; test widget sur la validation du
  formulaire "Signaler un problème" (description obligatoire) et sur le
  dialogue de création depuis un contrôle avec élément KO.

## Extensibilité future (matériel générique)

`tentId` reste une colonne directe (pas de relation polymorphique) — pas de
sur-ingénierie pour un besoin pas encore défini. Le jour où le matériel
générique est traité, ce sera une migration à part (nouvelle table
`materiels`, `tentId` rendu nullable, ajout d'un `materielId`), à concevoir
avec son propre design à ce moment-là.
