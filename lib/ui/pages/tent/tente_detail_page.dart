import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:logistiscout/ui/controllers/controle_controller.dart';
import 'package:logistiscout/ui/controllers/tentes_controller.dart';
import 'package:logistiscout/ui/pages/control/controle_detail_page.dart';
import 'package:logistiscout/ui/pages/control/controle_edit_page.dart';
import 'package:logistiscout/ui/pages/control/controle_saisie_nom_page.dart';
import 'package:logistiscout/ui/pages/event/evenement_detail_page.dart';
import 'package:logistiscout/ui/pages/tent/widgets/tente_action_journal_section.dart';
import 'package:logistiscout/ui/pages/tent/widgets/tente_control_history_section.dart';
import 'package:logistiscout/ui/pages/tent/widgets/tente_detail_common_widgets.dart';
import 'package:logistiscout/ui/pages/tent/widgets/tente_event_history_section.dart';
import 'package:logistiscout/ui/widgets/common/hearder_card.dart';

class TenteDetailPage extends ConsumerStatefulWidget {
  final int tentId;
  const TenteDetailPage({super.key, required this.tentId});

  @override
  ConsumerState<TenteDetailPage> createState() => _TenteDetailPageState();
}

class _TenteDetailPageState extends ConsumerState<TenteDetailPage> {
  // nullable controllers (init lazily when data available)
  TextEditingController? _nameCtl;
  TextEditingController? _nbCtl;
  TextEditingController? _colorChipsCtl;
  TextEditingController? _commentCtl;
  TextEditingController? _teamCtl;
  TextEditingController? _locationCtl;

  // local editable state (nullable until we see data)
  String? _tentType;
  int? _tentStatusId;
  String? _tentStatusLabel;
  int? _tentStatusColor;
  bool? _estIntegree;
  List<String>? _colorHexList;
  int? _favoriteUnitId;
  bool _favoriteUnitInitialized = false;
  Tent? _currentTent;
  Timer? _autosaveTimer;
  Future<void>? _autosaveInFlight;
  bool _autosaveListenersAttached = false;
  bool _draftDirty = false;
  bool _isAutosaving = false;

  static const _types = ['Canadienne', 'Tipi', 'Marabout', 'Autre'];

  TentState get _tentStateFallback {
    return tentStateFromString(
      _tentStatusLabel ?? tentStateToString(TentState.broken),
    );
  }

  void _applyLegacyState(TentState state) {
    _tentStatusId = null;
    _tentStatusLabel = tentStateToString(state);
    _tentStatusColor = state.chipColor;
  }

  TentStatusRef? _statusById(List<TentStatusRef> statuses, int? id) {
    if (id == null) return null;
    for (final status in statuses) {
      if (status.id == id) return status;
    }
    return null;
  }

  List<TentStatusRef> _sortedStatuses(List<TentStatusRef> statuses) {
    final seenIds = <int>{};
    final out = <TentStatusRef>[];
    for (final status in statuses) {
      if (status.isArchived) continue;
      if (seenIds.add(status.id)) {
        out.add(status);
      }
    }
    out.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      return a.id.compareTo(b.id);
    });
    return out;
  }

  void _ensureControllersAndState(Tent t) {
    _currentTent = t;

    _nameCtl ??= TextEditingController(text: t.nom);
    _nbCtl ??= TextEditingController(text: t.nbPlaces.toString());
    _commentCtl ??= TextEditingController(text: t.comment);
    _teamCtl ??= TextEditingController(text: t.team);
    _locationCtl ??= TextEditingController(text: t.location);

    _tentType ??= (_types.contains(t.tentType) ? t.tentType : 'Autre');
    _tentStatusId ??= t.tentStatusId;
    _tentStatusLabel ??= t.tentStatusLabel ?? tentStateToString(t.state);
    _tentStatusColor ??= t.tentStatusColor ?? t.state.chipColor;
    _estIntegree ??= t.isFloorEmbedded;
    if (!_favoriteUnitInitialized) {
      _favoriteUnitId = t.uniteId;
      _favoriteUnitInitialized = true;
    }

    _colorHexList ??= List<String>.from(t.colors);

    _attachAutosaveListeners();
  }

  void _attachAutosaveListeners() {
    if (_autosaveListenersAttached) {
      return;
    }

    _autosaveListenersAttached = true;
    _nameCtl?.addListener(_queueAutosave);
    _nbCtl?.addListener(_queueAutosave);
    _commentCtl?.addListener(_queueAutosave);
    _teamCtl?.addListener(_queueAutosave);
    _locationCtl?.addListener(_queueAutosave);
  }

  void _queueAutosave() {
    if (_currentTent == null) {
      return;
    }

    _draftDirty = true;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 1500), () {
      unawaited(_saveDraft());
    });

    if (mounted) {
      setState(() {});
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }

    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }

    return true;
  }

  String _selectedUnitName(List<GroupUnit> groupUnits, int? favoriteUnitId) {
    if (favoriteUnitId == null) {
      return '';
    }

    for (final unit in groupUnits) {
      if (int.tryParse(unit.id) == favoriteUnitId) {
        return unit.name;
      }
    }

    return '';
  }

  Tent _buildUpdatedTent(Tent tente, List<GroupUnit> groupUnits) {
    return tente.copyWith(
      nom: _nameCtl!.text.trim(),
      nbPlaces: int.tryParse(_nbCtl!.text.trim()) ?? tente.nbPlaces,
      tentType: _tentType!,
      state: _tentStateFallback,
      tentStatusId: _tentStatusId,
      tentStatusLabel: _tentStatusLabel,
      tentStatusColor: _tentStatusColor,
      uniteId: _favoriteUnitId,
      assignedUnit: _selectedUnitName(groupUnits, _favoriteUnitId),
      isFloorEmbedded: _estIntegree!,
      colors: _colorHexList!,
      team: _teamCtl!.text.trim(),
      location: _locationCtl!.text.trim(),
    );
  }

  bool _hasTentChanged(Tent original, Tent updated) {
    return original.nom != updated.nom ||
        original.nbPlaces != updated.nbPlaces ||
        original.tentType != updated.tentType ||
        original.state != updated.state ||
        original.tentStatusId != updated.tentStatusId ||
        original.tentStatusLabel != updated.tentStatusLabel ||
        original.tentStatusColor != updated.tentStatusColor ||
        original.uniteId != updated.uniteId ||
        original.assignedUnit != updated.assignedUnit ||
        original.isFloorEmbedded != updated.isFloorEmbedded ||
        !_listEquals(original.colors, updated.colors) ||
        original.team != updated.team ||
        original.location != updated.location;
  }

  Future<void> _saveDraft({bool force = false}) async {
    final tent = _currentTent;
    if (tent == null) {
      return;
    }

    _autosaveTimer?.cancel();
    _autosaveTimer = null;

    if (_isAutosaving) {
      return;
    }

    if (!_draftDirty && !force) {
      return;
    }

    final updated = _buildUpdatedTent(
      tent,
      ref.read(accountControllerProvider).valueOrNull?.units ??
          const <GroupUnit>[],
    );
    if (!_hasTentChanged(tent, updated)) {
      _draftDirty = false;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _isAutosaving = true;
    if (mounted) {
      setState(() {});
    }

    final saveFuture = ref.read(tentesProvider.notifier).updateTente(updated);
    _autosaveInFlight = saveFuture;

    try {
      await saveFuture;
      _draftDirty = false;
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sauvegarde automatique impossible : $e')),
        );
      }
      debugPrintStack(label: 'Autosave tente failed', stackTrace: st);
    } finally {
      if (identical(_autosaveInFlight, saveFuture)) {
        _autosaveInFlight = null;
      }

      _isAutosaving = false;
      if (mounted) {
        setState(() {});
      }

      if (_draftDirty && _autosaveTimer == null) {
        _autosaveTimer = Timer(const Duration(milliseconds: 3500), () {
          unawaited(_saveDraft());
        });
      }
    }
  }

  Future<bool> _flushPendingAutosave() async {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;

    final inFlight = _autosaveInFlight;
    if (inFlight != null) {
      await inFlight;
    }

    if (_draftDirty) {
      await _saveDraft(force: true);
    }

    return true;
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _nameCtl?.dispose();
    _nbCtl?.dispose();
    _colorChipsCtl?.dispose();
    _commentCtl?.dispose();
    _teamCtl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tentAsync = ref.watch(tentesProvider);
    final controlAsync = ref.watch(controlProvider(widget.tentId));
    final eventAsync = ref.watch(evenementsParTenteProvider(widget.tentId));
    final groupUnits =
        ref.watch(accountControllerProvider).valueOrNull?.units ??
        const <GroupUnit>[];
    final statuses = _sortedStatuses(
      ref.watch(accountControllerProvider).valueOrNull?.tentStatuses ??
          const <TentStatusRef>[],
    );

    if (_tentStatusId != null && _statusById(statuses, _tentStatusId) == null) {
      _tentStatusId = null;
    }

    if (_tentStatusId == null && statuses.isNotEmpty) {
      final label = (_tentStatusLabel ?? '').trim().toLowerCase();
      for (final status in statuses) {
        if (status.name.trim().toLowerCase() == label) {
          _tentStatusId = status.id;
          _tentStatusLabel = status.name;
          _tentStatusColor = status.color;
          break;
        }
      }
    }

    if (_favoriteUnitId != null &&
        groupUnits.every((u) => int.tryParse(u.id) != _favoriteUnitId)) {
      _favoriteUnitId = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail tente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: () async {
              await ref.read(tentesProvider.notifier).reload();
              await ref.read(controlProvider(widget.tentId).notifier).reload();
            },
          ),
        ],
      ),
      body: tentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (tentes) {
          const InputDecoration inputDecoration = InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          );

          Tent? foundTent;
          for (final candidate in tentes) {
            if (candidate.id == widget.tentId) {
              foundTent = candidate;
              break;
            }
          }
          if (foundTent == null) {
            return const Center(child: Text('Tente introuvable.'));
          }

          final tente = foundTent;

          _ensureControllersAndState(tente);

          return WillPopScope(
            onWillPop: _flushPendingAutosave,
            child: controlAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Erreur chargement contrôles : $e')),
              data: (controles) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: HeaderCard(tent: tente),
                    ),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          // --- Informations générales ---
                          TenteSectionCard(
                            title: 'Informations générales',
                            child: Column(
                              children: [
                                TextField(
                                  controller: _nameCtl,
                                  onChanged: (_) => _queueAutosave(),
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Nom',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _nbCtl,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => _queueAutosave(),
                                        decoration: inputDecoration.copyWith(
                                          labelText: 'Capacité (nb places)',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue:
                                            _types.contains(_tentType!)
                                            ? _tentType
                                            : 'Autre',
                                        items: _types
                                            .map(
                                              (t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(
                                                  t,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) => setState(() {
                                          _tentType = v ?? 'Autre';
                                          _queueAutosave();
                                        }),
                                        decoration: inputDecoration.copyWith(
                                          labelText: 'Type de tente',
                                        ),
                                        isExpanded: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: statuses.isEmpty
                                          ? DropdownButtonFormField<TentState>(
                                              initialValue: _tentStateFallback,
                                              items: TentState.values
                                                  .map(
                                                    (e) => DropdownMenuItem(
                                                      value: e,
                                                      child: Text(
                                                        tentStateToString(e),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (v) => setState(
                                                () => _applyLegacyState(
                                                  v ?? TentState.broken,
                                                ),
                                              ),
                                              decoration: inputDecoration
                                                  .copyWith(
                                                    labelText: 'Statut',
                                                  ),
                                              isExpanded: true,
                                            )
                                          : DropdownButtonFormField<int?>(
                                              initialValue:
                                                  _statusById(
                                                        statuses,
                                                        _tentStatusId,
                                                      ) !=
                                                      null
                                                  ? _tentStatusId
                                                  : null,
                                              items: statuses
                                                  .map(
                                                    (e) =>
                                                        DropdownMenuItem<int?>(
                                                          value: e.id,
                                                          child: Text(
                                                            e.name,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                              onChanged: (v) => setState(() {
                                                final selected = _statusById(
                                                  statuses,
                                                  v,
                                                );
                                                _tentStatusId = selected?.id;
                                                _tentStatusLabel =
                                                    selected?.name;
                                                _tentStatusColor =
                                                    selected?.color;
                                                _queueAutosave();
                                              }),
                                              decoration: inputDecoration
                                                  .copyWith(
                                                    labelText: 'Statut',
                                                  ),
                                              isExpanded: true,
                                            ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: DropdownButtonFormField<int?>(
                                        initialValue: _favoriteUnitId,
                                        items: [
                                          const DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text(
                                              'Aucune unité préférée',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          ...groupUnits
                                              .map(
                                                (e) => DropdownMenuItem<int?>(
                                                  value: int.tryParse(e.id),
                                                  child: Text(
                                                    e.name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .where(
                                                (item) => item.value != null,
                                              )
                                              .cast<DropdownMenuItem<int?>>(),
                                        ],
                                        onChanged: (v) => setState(() {
                                          _favoriteUnitId = v;
                                          _queueAutosave();
                                        }),
                                        decoration: inputDecoration.copyWith(
                                          labelText: 'Unité',
                                        ),
                                        isExpanded: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _teamCtl,
                                        onChanged: (_) => _queueAutosave(),
                                        decoration: inputDecoration.copyWith(
                                          labelText: 'Équipe',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: TextField(
                                        controller: _locationCtl,
                                        onChanged: (_) => _queueAutosave(),
                                        decoration: inputDecoration.copyWith(
                                          labelText: 'Localisation',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Tapis de sol intégré'),
                                  value: _estIntegree!,
                                  onChanged: (v) => setState(() {
                                    _estIntegree = v;
                                    _queueAutosave();
                                  }),
                                ),
                                const SizedBox(height: 4),
                                const TenteRowLabel('Couleurs'),
                                const SizedBox(height: 6),
                                TenteColorChipsEditor(
                                  colorsHex: _colorHexList!,
                                  onAdd: (hex) => setState(() {
                                    _colorHexList!.add(hex);
                                    _queueAutosave();
                                  }),
                                  onRemove: (hex) => setState(() {
                                    _colorHexList!.remove(hex);
                                    _queueAutosave();
                                  }),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.qr_code),
                                      onPressed: () async {
                                        final qrKey = GlobalKey();
                                        await showDialog(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            title: Text(
                                              'QR Code - ${tente.nom}',
                                            ),
                                            content: RepaintBoundary(
                                              key: qrKey,
                                              child: Container(
                                                color: Colors.white,
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 280,
                                                    height: 280,
                                                    child: FittedBox(
                                                      fit: BoxFit.contain,
                                                      child: ref
                                                          .read(
                                                            tentesProvider
                                                                .notifier,
                                                          )
                                                          .createTenteQrCode(
                                                            tente,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  dialogContext,
                                                ),
                                                child: const Text('Fermer'),
                                              ),
                                              ElevatedButton.icon(
                                                icon: const Icon(
                                                  Icons.save_alt,
                                                ),
                                                label: const Text(
                                                  'Sauver dans la galerie',
                                                ),
                                                onPressed: () async {
                                                  final result =
                                                      await _saveQrCodeImage(
                                                        qrKey,
                                                        tente.nom,
                                                      );
                                                  if (dialogContext.mounted) {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop();
                                                  }
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(result),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        child: _isAutosaving
                                            ? const Padding(
                                                key: ValueKey('autosaving'),
                                                padding: EdgeInsets.all(2),
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.4,
                                                    ),
                                              )
                                            : Icon(
                                                _draftDirty
                                                    ? Icons.cloud_off
                                                    : Icons.cloud_done,
                                                key: ValueKey(
                                                  _draftDirty
                                                      ? 'dirty'
                                                      : 'clean',
                                                ),
                                                size: 22,
                                                color: _draftDirty
                                                    ? Colors.red.shade600
                                                    : Colors.green.shade600,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          TenteControlHistorySection(
                            controls: controles,
                            tent: tente,
                            formatDate: _fmtDate,
                          ),

                          const SizedBox(height: 16),

                          eventAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) =>
                                Text('Erreur chargement événements : $e'),
                            data: (evenements) => TenteEventHistorySection(
                              events: evenements,
                              formatDate: _fmtDate,
                            ),
                          ),

                          const SizedBox(height: 16),

                          TenteActionJournalSection(
                            controls: controles,
                            tent: tente,
                            formatDate: _fmtDate,
                          ),

                          const SizedBox(height: 16),

                          // --- Remarques ---
                          TenteSectionCard(
                            title: 'Remarques',
                            child: Column(
                              children: [
                                TextField(
                                  controller: _commentCtl,
                                  maxLines: 3,
                                  onChanged: (_) => _queueAutosave(),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Notes sur la tente…',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: AnimatedOpacity(
                                    opacity: _isAutosaving ? 1 : 0.45,
                                    duration: const Duration(milliseconds: 150),
                                    child: const Text(
                                      'Sauvegarde automatique',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 80,
                          ), // space for bottom buttons
                        ],
                      ),
                    ),

                    // 🟢 BOUTONS FIXES EN BAS
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              offset: const Offset(0, -2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.assignment_turned_in),
                                label: const Text('Faire un contrôle'),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ControllerPageName.controlerNamePage(
                                            onNomValide: (nomControleur) async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ControlEditPage(
                                                        tent: tente,
                                                        controllerName:
                                                            nomControleur,
                                                      ),
                                                ),
                                              );
                                              await ref
                                                  .read(
                                                    controlProvider(
                                                      tente.id,
                                                    ).notifier,
                                                  )
                                                  .reload();
                                            },
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red.shade300),
                                  foregroundColor: Colors.red.shade700,
                                ),
                                icon: const Icon(Icons.delete_forever),
                                label: const Text('Supprimer'),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Supprimer la tente ?'),
                                      content: Text(
                                        'Supprimer « ${tente.nom} » ? Cette action est irréversible.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Annuler'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref
                                        .read(tentesProvider.notifier)
                                        .deleteTente(tente.id);
                                    if (mounted) Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

Future<String> _saveQrCodeImage(GlobalKey qrKey, String name) async {
  final boundary =
      qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('QR code indisponible');
  }

  final pixelRatio = math.max(
    2.0,
    ui.PlatformDispatcher.instance.views.first.devicePixelRatio,
  );
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Impossible de générer le PNG');
  }

  final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
  final bytes = byteData.buffer.asUint8List();

  final saveResult = await SaverGallery.saveImage(
    bytes,
    quality: 100,
    fileName: 'qr_tente_$safeName',
    skipIfExists: false,
  );

  if (saveResult.isSuccess) {
    return 'QR code enregistré dans la galerie';
  }

  // Fallback local file path if gallery save fails.
  final directory =
      await getExternalStorageDirectory() ??
      await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/qr_tente_$safeName.png');
  await file.writeAsBytes(bytes, flush: true);
  return 'Échec galerie, QR code enregistré localement: ${file.path}';
}
