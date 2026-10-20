import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/data/repositories/group_repository.dart';
import 'package:logistiscout/domain/entities/home_tile.dart';

/// Vignettes de l'aperçu de l'accueil, partagées par tout le groupe.
class HomeTilesController extends AsyncNotifier<List<HomeTile>> {
  GroupRepository get _repository => ref.read(groupRepositoryProvider);

  @override
  FutureOr<List<HomeTile>> build() async {
    try {
      return HomeTile.withMissingDefaults(await _repository.getHomeTiles());
    } catch (_) {
      // Hors ligne ou API plus ancienne : l'accueil garde l'aperçu d'origine.
      return HomeTile.defaults;
    }
  }

  List<HomeTile> get _current => state.valueOrNull ?? HomeTile.defaults;

  Future<void> _save(List<HomeTile> tiles) async {
    final previous = _current;
    state = AsyncData(tiles);
    try {
      state = AsyncData(await _repository.saveHomeTiles(tiles));
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Ajoute la vignette, ou remplace celle qui a le même id.
  Future<void> upsert(HomeTile tile) {
    final tiles = _current;
    final index = tiles.indexWhere((t) => t.id == tile.id);
    if (index == -1) return _save([...tiles, tile]);
    return _save([...tiles]..[index] = tile);
  }

  Future<void> setVisible(String id, bool visible) {
    return _save([
      for (final t in _current) t.id == id ? t.copyWith(visible: visible) : t,
    ]);
  }

  /// [newIndex] est la position finale de la vignette.
  Future<void> reorder(int oldIndex, int newIndex) {
    final tiles = [..._current];
    final tile = tiles.removeAt(oldIndex);
    tiles.insert(newIndex.clamp(0, tiles.length), tile);
    return _save(tiles);
  }

  Future<void> remove(String id) {
    return _save(_current.where((t) => t.id != id || !t.isCustom).toList());
  }

  Future<void> resetDefaults() async {
    state = AsyncData(await _repository.resetHomeTiles());
  }
}
