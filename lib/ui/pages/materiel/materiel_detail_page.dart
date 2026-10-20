import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/issue.dart';
import 'package:logistiscout/domain/entities/item.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/ui/controllers/items_controller.dart';
import 'package:logistiscout/ui/pages/materiel/materiel_page.dart';
import 'package:logistiscout/ui/pages/tent/widgets/tente_detail_common_widgets.dart';
import 'package:logistiscout/ui/widgets/common/item_card.dart';
import 'package:logistiscout/ui/widgets/common/item_visuals.dart';
import 'package:logistiscout/ui/widgets/issues/issue_dialog.dart';
import 'package:logistiscout/ui/widgets/issues/issues_section.dart';

/// Fiche d'un matériel : même structure que la fiche tente, enregistrement
/// automatique des modifications.
class MaterielDetailPage extends ConsumerStatefulWidget {
  final int itemId;

  const MaterielDetailPage({super.key, required this.itemId});

  @override
  ConsumerState<MaterielDetailPage> createState() => _MaterielDetailPageState();
}

class _MaterielDetailPageState extends ConsumerState<MaterielDetailPage> {
  TextEditingController? _nameCtl;
  TextEditingController? _quantityCtl;
  TextEditingController? _thresholdCtl;
  TextEditingController? _teamCtl;
  TextEditingController? _locationCtl;
  TextEditingController? _commentCtl;
  final Map<String, TextEditingController> _fieldCtls = {};

  String? _typeKey;
  int? _statusId;
  int? _unitId;
  bool? _consumable;
  List<String>? _colors;

  Item? _currentItem;
  Timer? _autosaveTimer;
  Future<void>? _autosaveInFlight;
  bool _draftDirty = false;
  bool _isAutosaving = false;

  void _ensureState(Item item) {
    _currentItem = item;
    if (_nameCtl != null) return;
    _nameCtl = TextEditingController(text: item.nom);
    _quantityCtl = TextEditingController(text: '${item.quantity}');
    _thresholdCtl = TextEditingController(
      text: item.threshold?.toString() ?? '',
    );
    _teamCtl = TextEditingController(text: item.equipe);
    _locationCtl = TextEditingController(text: item.localisation);
    _commentCtl = TextEditingController(text: item.remarques);
    _typeKey = item.typeKey;
    _statusId = item.statusId;
    _unitId = item.uniteId;
    _consumable = item.isConsumable;
    _colors = List<String>.from(item.colors);
  }

  TextEditingController _fieldCtl(ItemTypeField field) {
    return _fieldCtls.putIfAbsent(
      field.key,
      () => TextEditingController(
        text: _currentItem?.fields[field.key]?.toString() ?? '',
      ),
    );
  }

  void _queueAutosave() {
    if (_currentItem == null) return;
    _draftDirty = true;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 1500), () {
      unawaited(_saveDraft());
    });
    if (mounted) setState(() {});
  }

  Item _buildUpdatedItem(Item item) {
    final fields = Map<String, dynamic>.from(item.fields);
    for (final entry in _fieldCtls.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) {
        fields.remove(entry.key);
      } else {
        fields[entry.key] = num.tryParse(value.replaceAll(',', '.')) ?? value;
      }
    }
    return item.copyWith(
      nom: _nameCtl!.text.trim().isEmpty ? item.nom : _nameCtl!.text.trim(),
      quantity: int.tryParse(_quantityCtl!.text.trim()) ?? item.quantity,
      typeKey: _typeKey,
      statusId: () => _statusId,
      uniteId: () => _unitId,
      isConsumable: _consumable,
      threshold: () =>
          _consumable == true ? int.tryParse(_thresholdCtl!.text.trim()) : null,
      equipe: _teamCtl!.text.trim(),
      localisation: _locationCtl!.text.trim(),
      remarques: _commentCtl!.text.trim(),
      colors: _colors,
      fields: fields,
    );
  }

  Future<void> _saveDraft({bool force = false}) async {
    final item = _currentItem;
    if (item == null) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    if (_isAutosaving || (!_draftDirty && !force)) return;

    _isAutosaving = true;
    if (mounted) setState(() {});

    final saveFuture = ref
        .read(itemsProvider.notifier)
        .updateItem(_buildUpdatedItem(item));
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
      debugPrintStack(label: 'Autosave matériel failed', stackTrace: st);
    } finally {
      if (identical(_autosaveInFlight, saveFuture)) _autosaveInFlight = null;
      _isAutosaving = false;
      if (mounted) setState(() {});
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
    if (inFlight != null) await inFlight;
    if (_draftDirty) await _saveDraft(force: true);
    return true;
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    for (final ctl in [
      _nameCtl,
      _quantityCtl,
      _thresholdCtl,
      _teamCtl,
      _locationCtl,
      _commentCtl,
      ..._fieldCtls.values,
    ]) {
      ctl?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);
    final types = ref.watch(itemTypesProvider).valueOrNull ?? const [];
    final group = ref.watch(accountControllerProvider).valueOrNull;
    final groupUnits = group?.units ?? const <GroupUnit>[];
    final statuses = sortedItemStatuses(
      group?.tentStatuses ?? const <TentStatusRef>[],
    );

    if (_statusId != null && statuses.every((s) => s.id != _statusId)) {
      _statusId = null;
    }
    if (_unitId != null &&
        groupUnits.every((u) => int.tryParse(u.id) != _unitId)) {
      _unitId = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail matériel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: () async {
              await ref.read(itemsProvider.notifier).reload();
              ref.invalidate(
                openIssuesForTargetProvider(IssueTarget.item(widget.itemId)),
              );
            },
          ),
        ],
      ),
      body: itemsAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (items) {
          final item = items.where((i) => i.id == widget.itemId).firstOrNull;
          if (item == null) {
            return const Center(child: Text('Matériel introuvable.'));
          }
          _ensureState(item);

          const inputDecoration = InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          );
          final sortedTypes = [...types]
            ..sort((a, b) => a.name.compareTo(b.name));
          final type = itemTypeByKey(types, _typeKey ?? item.typeKey);

          return WillPopScope(
            onWillPop: _flushPendingAutosave,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ItemHeaderCard(item: item),
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
                                    controller: _quantityCtl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => _queueAutosave(),
                                    decoration: inputDecoration.copyWith(
                                      labelText: 'Quantité',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: type?.key,
                                    isExpanded: true,
                                    items: sortedTypes
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t.key,
                                            child: Text(
                                              t.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) => setState(() {
                                      _typeKey = v ?? _typeKey;
                                      _queueAutosave();
                                    }),
                                    decoration: inputDecoration.copyWith(
                                      labelText: 'Type',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    initialValue: _statusId,
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Aucun'),
                                      ),
                                      ...statuses.map(
                                        (s) => DropdownMenuItem<int?>(
                                          value: s.id,
                                          child: Text(
                                            s.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) => setState(() {
                                      _statusId = v;
                                      _queueAutosave();
                                    }),
                                    decoration: inputDecoration.copyWith(
                                      labelText: 'Statut',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    initialValue: _unitId,
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text(
                                          'Aucune unité préférée',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      for (final u in groupUnits)
                                        if (int.tryParse(u.id) != null)
                                          DropdownMenuItem<int?>(
                                            value: int.parse(u.id),
                                            child: Text(
                                              u.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                    ],
                                    onChanged: (v) => setState(() {
                                      _unitId = v;
                                      _queueAutosave();
                                    }),
                                    decoration: inputDecoration.copyWith(
                                      labelText: 'Unité',
                                    ),
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
                            // Champs propres au type (volume, nombre de feux…).
                            for (final field
                                in type?.fields ?? const <ItemTypeField>[]) ...[
                              const SizedBox(height: 15),
                              TextField(
                                controller: _fieldCtl(field),
                                keyboardType: field.isNumber
                                    ? const TextInputType.numberWithOptions(
                                        decimal: true,
                                      )
                                    : TextInputType.text,
                                onChanged: (_) => _queueAutosave(),
                                decoration: inputDecoration.copyWith(
                                  labelText: field.label,
                                ),
                              ),
                            ],
                            const SizedBox(height: 15),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Consommable'),
                              value: _consumable!,
                              onChanged: (v) => setState(() {
                                _consumable = v;
                                _queueAutosave();
                              }),
                            ),
                            if (_consumable!) ...[
                              const SizedBox(height: 4),
                              TextField(
                                controller: _thresholdCtl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _queueAutosave(),
                                decoration: inputDecoration.copyWith(
                                  labelText: 'Seuil de rachat',
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            const TenteRowLabel('Couleurs'),
                            const SizedBox(height: 6),
                            TenteColorChipsEditor(
                              colorsHex: _colors!,
                              onAdd: (hex) => setState(() {
                                _colors!.add(hex);
                                _queueAutosave();
                              }),
                              onRemove: (hex) => setState(() {
                                _colors!.remove(hex);
                                _queueAutosave();
                              }),
                            ),
                            const SizedBox(height: 15),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  child: _isAutosaving
                                      ? const Padding(
                                          key: ValueKey('autosaving'),
                                          padding: EdgeInsets.all(2),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                          ),
                                        )
                                      : Icon(
                                          _draftDirty
                                              ? Icons.cloud_off
                                              : Icons.cloud_done,
                                          key: ValueKey(
                                            _draftDirty ? 'dirty' : 'clean',
                                          ),
                                          size: 22,
                                          color: _draftDirty
                                              ? Colors.red.shade600
                                              : Colors.green.shade600,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      IssuesSection(
                        target: IssueTarget.item(item.id),
                        targetName: item.nom,
                        maxQuantity: item.quantity,
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
                                hintText: 'Notes sur le matériel…',
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
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // Boutons fixes en bas, comme sur la fiche tente. Le contrôle
                // par check-list du matériel arrive en V2 : on signale ici.
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, -2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.report_problem_outlined),
                            label: const Text('Signaler'),
                            onPressed: () => showIssueDialog(
                              context,
                              target: IssueTarget.item(item.id),
                              targetName: item.nom,
                              maxQuantity: item.quantity,
                            ),
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
                            onPressed: () => _confirmDelete(item),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Item item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le matériel ?'),
        content: Text(
          'Retirer « ${item.nom} » de la liste ? Ses signalements restent '
          'dans l\'historique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    _autosaveTimer?.cancel();
    _draftDirty = false;
    try {
      await ref.read(itemsProvider.notifier).deleteItem(item.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Suppression impossible : $e')));
    }
  }
}
