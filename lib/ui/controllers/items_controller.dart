import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/data/repositories/item_repository.dart';
import 'package:logistiscout/domain/entities/issue.dart';
import 'package:logistiscout/domain/entities/item.dart';

/// Matériel hors tentes du groupe, trié par nom.
class ItemsController extends AsyncNotifier<List<Item>> {
  ItemRepository get _repo => ref.read(itemRepositoryProvider);

  @override
  FutureOr<List<Item>> build() => _load();

  Future<List<Item>> _load() async {
    return _sorted(await _repo.getItems());
  }

  static List<Item> _sorted(List<Item> items) {
    return [...items]
      ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
  }

  List<Item> get _current => state.valueOrNull ?? const [];

  /// Garde la liste affichée pendant le rechargement (pas de saut d'écran).
  Future<void> reload() async {
    state = const AsyncLoading<List<Item>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_load);
  }

  Future<Item> createItem(Item item) async {
    final created = await _repo.createItem(item);
    state = AsyncData(_sorted([..._current, created]));
    return created;
  }

  Future<Item> updateItem(Item item) async {
    final updated = await _repo.updateItem(item);
    state = AsyncData(
      _sorted([
        for (final i in _current) i.id == updated.id ? updated : i,
      ]),
    );
    return updated;
  }

  Future<void> deleteItem(int id) async {
    await _repo.deleteItem(id);
    state = AsyncData(_current.where((i) => i.id != id).toList());
  }
}

final itemsProvider = AsyncNotifierProvider<ItemsController, List<Item>>(
  ItemsController.new,
);

/// Catalogue de base (ne change pas pendant la session).
final itemTypesProvider = FutureProvider<List<ItemType>>((ref) {
  return ref.read(itemRepositoryProvider).getItemTypes();
});

/// Signalements ouverts d'une tente ou d'un matériel.
final openIssuesForTargetProvider =
    FutureProvider.family<List<Issue>, IssueTarget>((ref, target) {
      return ref
          .read(itemRepositoryProvider)
          .getIssues(target: target, state: IssueState.open);
    });

/// Tous les signalements ouverts du groupe (vignette d'accueil).
final openIssuesProvider = FutureProvider<List<Issue>>((ref) {
  return ref.read(itemRepositoryProvider).getIssues(state: IssueState.open);
});

/// Ouvrir ou clore un signalement, puis rafraîchir ce qui en dépend.
class IssueActions {
  IssueActions(this._ref);

  final Ref _ref;

  ItemRepository get _repo => _ref.read(itemRepositoryProvider);

  Future<Issue> report({
    required IssueTarget target,
    required String description,
    required bool usable,
    int quantity = 1,
    String? reporterName,
    Uint8List? photoBytes,
    String? photoName,
  }) async {
    var issue = await _repo.createIssue(
      target: target,
      description: description,
      usable: usable,
      quantity: quantity,
      reporterName: reporterName,
    );
    try {
      if (photoBytes != null) {
        issue = await _repo.uploadIssuePicture(
          issueId: issue.id,
          bytes: photoBytes,
          fileName: photoName ?? 'signalement.jpg',
        );
      }
    } finally {
      // Le signalement existe même si la photo n'a pas pu partir.
      await _refresh(target);
    }
    return issue;
  }

  Future<void> setState(Issue issue, IssueState state) async {
    await _repo.setIssueState(issue.id, state);
    await _refresh(issue.target);
  }

  Future<void> _refresh(IssueTarget target) async {
    _ref.invalidate(openIssuesForTargetProvider(target));
    _ref.invalidate(openIssuesProvider);
    if (target.kind == IssueTargetKind.item) {
      // L'état d'usage et la quantité utilisable sont recalculés par l'API.
      await _ref.read(itemsProvider.notifier).reload();
    }
  }
}

final issueActionsProvider = Provider<IssueActions>(IssueActions.new);
