import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/domain/entities/home_tile.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/tente.dart';

void main() {
  TentStatusRef status(int id, {required bool needsRepair}) => TentStatusRef(
    id: id,
    name: 'S$id',
    color: 0xFF000000,
    order: id,
    isDefault: false,
    isArchived: false,
    needsRepair: needsRepair,
  );

  Tent tent(int id, int statusId, {String type = 'Canadienne'}) => Tent(
    id: id,
    nom: 'Tente $id',
    uniteId: null,
    state: TentState.good,
    tentStatusId: statusId,
    tentStatusLabel: 'S$statusId',
    tentStatusColor: null,
    comment: '',
    isFloorEmbedded: false,
    nbPlaces: 4,
    tentType: type,
    assignedUnit: '',
    agenda: const [],
    controlHistory: const [],
    colors: const [],
    groupId: '1',
    team: '',
    location: '',
  );

  // 1 Correcte, 2 Séchage + correcte, 3 Séchage + réparation, 4 À réparer, 5 HS
  final statuses = [
    status(1, needsRepair: false),
    status(2, needsRepair: false),
    status(3, needsRepair: true),
    status(4, needsRepair: true),
    status(5, needsRepair: true),
  ];
  final data = HomeOverviewData(
    tents: [
      tent(1, 1),
      tent(2, 1, type: 'Tipi'),
      tent(3, 2),
      tent(4, 3, type: 'Tipi'),
      tent(5, 4),
      tent(6, 5),
    ],
    statuses: statuses,
    upcomingEventsCount: 2,
    usedTentsCount: 3,
  );

  HomeTile builtin(HomeTileKind kind, {List<int> statusIds = const []}) =>
      HomeTile(id: kind.jsonValue, kind: kind, statusIds: statusIds);

  group('homeTileCount', () {
    test('tentes, reparation, sorties, tentes utilisees', () {
      expect(homeTileCount(builtin(HomeTileKind.tents), data), 6);
      expect(homeTileCount(builtin(HomeTileKind.repair), data), 3);
      expect(homeTileCount(builtin(HomeTileKind.outings), data), 2);
      expect(homeTileCount(builtin(HomeTileKind.usedTents), data), 3);
    });

    test('operationnelles sans statut choisi = total - a reparer', () {
      expect(homeTileCount(builtin(HomeTileKind.operational), data), 3);
    });

    test('operationnelles avec statuts choisis', () {
      final tile = builtin(HomeTileKind.operational, statusIds: [1, 2, 3]);
      expect(homeTileCount(tile, data), 4);
    });

    test('vignette perso: statuts et type de materiel', () {
      const sechage = HomeTile(
        id: 'custom-1',
        kind: HomeTileKind.custom,
        title: 'En séchage',
        statusIds: [2, 3],
      );
      const sechageTipi = HomeTile(
        id: 'custom-2',
        kind: HomeTileKind.custom,
        title: 'Tipis en séchage',
        statusIds: [2, 3],
        tentTypes: ['Tipi'],
      );
      const toutTipi = HomeTile(
        id: 'custom-3',
        kind: HomeTileKind.custom,
        title: 'Tipis',
        tentTypes: ['Tipi'],
      );

      expect(homeTileCount(sechage, data), 2);
      expect(homeTileCount(sechageTipi, data), 1);
      expect(homeTileCount(toutTipi, data), 2);
    });
  });

  group('HomeTile json', () {
    test('aller-retour', () {
      const tile = HomeTile(
        id: 'custom-1',
        kind: HomeTileKind.custom,
        visible: false,
        title: 'En séchage',
        subtitle: 'chez les jeunes',
        color: 0xFF0E7490,
        icon: 'water',
        statusIds: [2, 3],
        tentTypes: ['Tipi'],
      );

      final parsed = HomeTile.fromJson(tile.toJson());

      expect(parsed.toJson(), tile.toJson());
      expect(tile.toJson()['kind'], 'custom');
      expect(
        HomeTile.fromJson({'id': 'used_tents', 'kind': 'used_tents'}).kind,
        HomeTileKind.usedTents,
      );
    });

    test('valeurs par defaut', () {
      expect(HomeTile.defaults.map((t) => t.id), [
        'tents',
        'operational',
        'repair',
        'outings',
        'used_tents',
        'items',
        'issues',
      ]);
      expect(
        HomeTile.defaults.firstWhere((t) => t.id == 'used_tents').visible,
        isFalse,
      );
    });

    test('les vignettes d origine absentes sont ajoutees a la fin', () {
      final saved = [
        const HomeTile(id: 'repair', kind: HomeTileKind.repair),
        const HomeTile(id: 'custom-1', kind: HomeTileKind.custom, title: 'HS'),
      ];

      final tiles = HomeTile.withMissingDefaults(saved);

      expect(tiles.take(2).map((t) => t.id), ['repair', 'custom-1']);
      expect(tiles.map((t) => t.id).toSet(), {
        'repair',
        'custom-1',
        'tents',
        'operational',
        'outings',
        'used_tents',
        'items',
        'issues',
      });
      expect(tiles.where((t) => t.id == 'repair').length, 1);
    });
  });
}
