import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/tente.dart';

void main() {
  TentStatusRef status(int id, String name, {required bool needsRepair}) {
    return TentStatusRef(
      id: id,
      name: name,
      color: 0xFF000000,
      order: id,
      isDefault: false,
      isArchived: false,
      needsRepair: needsRepair,
    );
  }

  Tent tent(int id, {int? statusId, String? label}) {
    return Tent(
      id: id,
      nom: 'Tente $id',
      uniteId: null,
      state: TentState.good,
      tentStatusId: statusId,
      tentStatusLabel: label,
      tentStatusColor: null,
      comment: '',
      isFloorEmbedded: false,
      nbPlaces: 4,
      tentType: 'Canadienne',
      assignedUnit: '',
      agenda: const [],
      controlHistory: const [],
      colors: const [],
      groupId: '1',
      team: '',
      location: '',
    );
  }

  group('TentStatusRef.fromJson', () {
    test('lit needsRepair', () {
      final parsed = TentStatusRef.fromJson({
        'id': 3,
        'name': 'Séchage',
        'needsRepair': true,
      });
      expect(parsed.needsRepair, isTrue);
    });

    test('sans needsRepair (ancien cache), deduit du nom', () {
      expect(TentStatusRef.fromJson({'name': 'Bon'}).needsRepair, isFalse);
      expect(TentStatusRef.fromJson({'name': 'Perdue'}).needsRepair, isFalse);
      expect(
        TentStatusRef.fromJson({'name': 'À réparer'}).needsRepair,
        isTrue,
      );
      expect(TentStatusRef.fromJson({'name': 'HS'}).needsRepair, isTrue);
    });

    test('toJson conserve needsRepair', () {
      final json = status(1, 'HS', needsRepair: true).toJson();
      expect(json['needsRepair'], isTrue);
    });
  });

  group('tentsNeedingRepair', () {
    final statuses = [
      status(1, 'Correcte', needsRepair: false),
      status(2, 'Séchage + correcte', needsRepair: false),
      status(3, 'Séchage + réparation', needsRepair: true),
      status(4, 'A Réparer', needsRepair: true),
      status(5, 'HS', needsRepair: true),
    ];

    test('ne retient que les statuts marques a reparer', () {
      final tents = [for (var i = 1; i <= 5; i++) tent(i, statusId: i)];

      final result = tentsNeedingRepair(tents, statuses);

      expect(result.map((t) => t.id), [3, 4, 5]);
    });

    test('statut inconnu: se rabat sur le libelle', () {
      final tents = [
        tent(1, statusId: 99, label: 'Bon'),
        tent(2, statusId: 98, label: 'À réparer'),
        tent(3, label: 'Perdue'),
      ];

      final result = tentsNeedingRepair(tents, const []);

      expect(result.map((t) => t.id), [2]);
    });
  });
}
