import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/domain/entities/issue.dart';
import 'package:logistiscout/domain/entities/item.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/ui/widgets/common/item_visuals.dart';

void main() {
  const statuses = [
    TentStatusRef(
      id: 1,
      name: 'Bon',
      color: 0xFFE8F5E9,
      order: 0,
      isDefault: true,
      isArchived: false,
    ),
    TentStatusRef(
      id: 2,
      name: 'À réparer',
      color: 0xFFFFF8E1,
      order: 1,
      isDefault: true,
      isArchived: false,
      needsRepair: true,
    ),
    TentStatusRef(
      id: 4,
      name: 'Perdue',
      color: 0xFFFAFAFA,
      order: 3,
      isDefault: true,
      isArchived: false,
    ),
  ];

  const vaisselle = ItemType(
    key: 'vaisselle',
    name: 'Vaisselle',
    family: 'Cuisine',
    tracking: ItemTracking.quantity,
    icon: 'soup_kitchen',
  );

  group('Item.fromJson', () {
    test('lit les champs et l etat deduit', () {
      final item = Item.fromJson({
        'id': 7,
        'typeKey': 'vaisselle',
        'nom': 'Gamelles',
        'quantity': 24,
        'statusId': 1,
        'uniteId': null,
        'isConsumable': false,
        'couleurs': ['#FF0000'],
        'fields': {'volume': 20},
        'usage': 'repair',
        'usableQuantity': 22,
        'openIssues': 1,
      });

      expect(item.id, 7);
      expect(item.quantity, 24);
      expect(item.usage, ItemUsage.repair);
      expect(item.usableQuantity, 22);
      expect(item.colors, ['#FF0000']);
      expect(item.fields['volume'], 20);
      expect(item.toJson().containsKey('usage'), isFalse);
    });

    test('copyWith peut vider un champ nullable', () {
      const item = Item(id: 1, typeKey: 'autre', nom: 'X', statusId: 2);
      expect(item.copyWith(statusId: () => null).statusId, isNull);
      expect(item.copyWith(nom: 'Y').statusId, 2);
    });
  });

  group('itemDisplayStatus', () {
    test('un probleme ouvert passe avant le statut choisi', () {
      const item = Item(
        id: 1,
        typeKey: 'vaisselle',
        nom: 'Gamelles',
        quantity: 24,
        statusId: 1,
        usage: ItemUsage.repair,
      );
      expect(itemDisplayStatus(item, statuses).label, 'À réparer');
    });

    test('hors service quand plus rien n est utilisable', () {
      const item = Item(
        id: 1,
        typeKey: 'jerrican',
        nom: 'J3',
        usage: ItemUsage.out,
      );
      expect(itemDisplayStatus(item, statuses).label, 'Hors service');
    });

    test('a racheter quand le stock atteint le seuil', () {
      const item = Item(
        id: 1,
        typeKey: 'cartouches_gaz',
        nom: 'Cartouches',
        quantity: 4,
        isConsumable: true,
        threshold: 10,
      );
      expect(item.needsRestock, isTrue);
      expect(itemDisplayStatus(item, statuses).label, 'À racheter');
    });

    test('sinon le statut du groupe', () {
      const item = Item(id: 1, typeKey: 'autre', nom: 'X', statusId: 4);
      final display = itemDisplayStatus(item, statuses);
      expect(display.label, 'Perdue');
      expect(display.color, 0xFFFAFAFA);
    });
  });

  test('libelle de quantite d un lot partiellement hors service', () {
    const item = Item(
      id: 1,
      typeKey: 'vaisselle',
      nom: 'Gamelles',
      quantity: 24,
      usableQuantity: 22,
    );
    expect(itemQuantityLabel(item, vaisselle), '22 / 24 utilisables');
  });

  test('IssueTarget compare par type et identifiant', () {
    expect(const IssueTarget.tent(8), const IssueTarget.tent(8));
    expect(const IssueTarget.tent(8) == const IssueTarget.item(8), isFalse);
  });

  test('Issue.fromJson relit la date UTC', () {
    final issue = Issue.fromJson({
      'id': 1,
      'targetKind': 'item',
      'targetId': 3,
      'description': 'Percée',
      'quantity': 2,
      'usable': false,
      'state': 'open',
      'createdAt': '2026-10-20T08:00:00',
    });
    expect(issue.target, const IssueTarget.item(3));
    expect(issue.usable, isFalse);
    expect(issue.createdAt.toUtc(), DateTime.utc(2026, 10, 20, 8));
  });
}
