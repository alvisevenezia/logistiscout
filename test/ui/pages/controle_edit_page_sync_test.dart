import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/ui/controllers/controle_controller.dart';
import 'package:logistiscout/ui/controllers/tentes_controller.dart';
import 'package:logistiscout/ui/pages/control/controle_edit_page.dart';

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
  final List<Control> added = [];

  @override
  Future<List<Control>> build(int arg) async => const [];

  @override
  Future<Control> addControl(Control control) async {
    added.add(control);
    return control.copyWith(id: 999);
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
  testWidgets(
    'la remarque du contrôle est synchronisée dans la remarque de la tente',
    (tester) async {
      final tentesController = FakeTentesController([buildTent(comment: '')]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tentesProvider.overrideWith(() => tentesController),
            controlProvider.overrideWith(FakeControlController.new),
          ],
          child: MaterialApp(
            home: ControlEditPage(
              tent: buildTent(comment: ''),
              controllerName: 'Alice',
            ),
          ),
        ),
      );

      await tester.pump();

      final remarquesField = find.widgetWithText(
        TextField,
        'Remarques générales',
      );
      await tester.scrollUntilVisible(
        remarquesField,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(remarquesField, 'Toile déchirée côté nord');
      await tester.pump();

      final validateButton = find.widgetWithText(
        ElevatedButton,
        'Valider le contrôle',
      );
      await tester.scrollUntilVisible(
        validateButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(validateButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        tentesController.updates,
        isNotEmpty,
        reason:
            'La validation du contrôle doit synchroniser la remarque vers la tente',
      );
      expect(
        tentesController.updates.last.comment,
        'Toile déchirée côté nord',
      );
    },
  );
}
