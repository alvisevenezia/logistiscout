import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/data/repositories/group_repository.dart';
import 'package:logistiscout/domain/entities/home_tile.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository repo;
  late ProviderContainer container;
  List<HomeTile>? saved;

  setUpAll(() => registerFallbackValue(<HomeTile>[]));

  setUp(() {
    repo = MockGroupRepository();
    saved = null;
    when(() => repo.getHomeTiles()).thenAnswer((_) async => HomeTile.defaults);
    when(() => repo.saveHomeTiles(any())).thenAnswer((invocation) async {
      saved = invocation.positionalArguments.first as List<HomeTile>;
      return saved!;
    });
    container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  List<String> ids() => container
      .read(homeTilesControllerProvider)
      .requireValue
      .map((t) => t.id)
      .toList();

  test('charge les vignettes du groupe', () async {
    final tiles = await container.read(homeTilesControllerProvider.future);
    expect(tiles.length, 5);
  });

  test('hors ligne: vignettes par defaut', () async {
    when(() => repo.getHomeTiles()).thenThrow(Exception('offline'));
    final tiles = await container.read(homeTilesControllerProvider.future);
    expect(tiles.map((t) => t.id), HomeTile.defaults.map((t) => t.id));
  });

  test('ajout, modification, masquage, ordre, suppression', () async {
    await container.read(homeTilesControllerProvider.future);
    final controller = container.read(homeTilesControllerProvider.notifier);

    const sechage = HomeTile(
      id: 'custom-1',
      kind: HomeTileKind.custom,
      title: 'En séchage',
      statusIds: [2],
    );
    await controller.upsert(sechage);
    expect(ids().last, 'custom-1');
    expect(saved!.last.title, 'En séchage');

    await controller.upsert(sechage.copyWith(title: 'Séchage'));
    expect(ids().where((id) => id == 'custom-1').length, 1);
    expect(saved!.last.title, 'Séchage');

    await controller.setVisible('tents', false);
    expect(saved!.first.visible, isFalse);

    await controller.reorder(5, 0);
    expect(ids().first, 'custom-1');

    await controller.remove('custom-1');
    expect(ids(), isNot(contains('custom-1')));
  });

  test('erreur de sauvegarde: on revient a l etat precedent', () async {
    await container.read(homeTilesControllerProvider.future);
    when(() => repo.saveHomeTiles(any())).thenThrow(Exception('500'));

    await expectLater(
      container
          .read(homeTilesControllerProvider.notifier)
          .setVisible('tents', false),
      throwsException,
    );
    expect(
      container.read(homeTilesControllerProvider).requireValue.first.visible,
      isTrue,
    );
  });
}
