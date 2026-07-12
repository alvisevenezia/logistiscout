import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/group.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/entities/unit.dart';
import 'package:logistiscout/ui/controllers/controle_controller.dart';
import 'package:logistiscout/ui/controllers/group_settings_controller.dart';
import 'package:logistiscout/ui/controllers/tentes_controller.dart';
import 'package:logistiscout/ui/pages/tent/tente_detail_page.dart';

class FakeTentesController extends TentesController {
  FakeTentesController(this.initialTents);

  final List<Tent> initialTents;
  final List<Tent> updates = [];

  @override
  Future<List<Tent>> build() async => initialTents;

  @override
  Future<void> updateTente(Tent tente) async {
    updates.add(tente);
    final current = state.valueOrNull ?? initialTents;
    state = AsyncValue.data(
      current.map((t) => t.id == tente.id ? tente : t).toList(),
    );
  }
}

class FakeControlController extends ControlController {
  @override
  Future<List<Control>> build(int arg) async => const [];
}

class FakeAccountController extends GroupSettingsController {
  @override
  Future<Group> build() async {
    return Group(
      id: '1',
      name: 'Groupe Alpha',
      email: 'alpha@example.com',
      members: '[]',
      login: 'alpha_login',
      type: 'scout',
      units: [
        GroupUnit(id: '10', name: 'Groupe', color: 0xFF420068, type: Unit.groupe),
      ],
      tentStatuses: const [
        TentStatusRef(
          id: 1,
          name: 'Bon',
          color: 0xFF388E3C,
          order: 0,
          isDefault: true,
          isArchived: false,
        ),
      ],
    );
  }
}

Tent buildTent({int id = 1, String comment = ''}) {
  return Tent(
    id: id,
    nom: 'Tente A',
    uniteId: null,
    state: TentState.good,
    tentStatusId: 1,
    tentStatusLabel: 'Bon',
    tentStatusColor: 0xFF388E3C,
    comment: comment,
    isFloorEmbedded: false,
    nbPlaces: 6,
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

void main() {
  testWidgets('la modification des remarques est sauvegardée automatiquement', (
    tester,
  ) async {
    final tentesController = FakeTentesController([buildTent()]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tentesProvider.overrideWith(() => tentesController),
          controlProvider.overrideWith(FakeControlController.new),
          accountControllerProvider.overrideWith(FakeAccountController.new),
          evenementsParTenteProvider.overrideWith(
            (ref, tentId) async => const <Event>[],
          ),
        ],
        child: const MaterialApp(home: TenteDetailPage(tentId: 1)),
      ),
    );

    await tester.pump();
    await tester.pump();

    final remarquesField = find.widgetWithText(TextField, 'Notes sur la tente…');
    await tester.scrollUntilVisible(
      remarquesField,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.enterText(remarquesField, 'Toile déchirée côté nord');

    // Laisse passer le délai d'autosave (1500 ms) puis la sauvegarde async.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(
      tentesController.updates,
      isNotEmpty,
      reason: 'La modification des remarques doit déclencher une sauvegarde',
    );
    expect(tentesController.updates.last.comment, 'Toile déchirée côté nord');
  });
}
