import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/issue.dart';
import 'package:logistiscout/domain/entities/item.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/ui/controllers/items_controller.dart';
import 'package:logistiscout/ui/widgets/common/item_card.dart';
import 'package:logistiscout/ui/widgets/common/item_visuals.dart';
import 'package:logistiscout/ui/widgets/issues/issue_dialog.dart';

/// Liste du matériel hors tentes : même organisation que la page Tentes.
class MaterielPage extends ConsumerStatefulWidget {
  const MaterielPage({super.key});

  @override
  ConsumerState<MaterielPage> createState() => _MaterielPageState();
}

class _MaterielPageState extends ConsumerState<MaterielPage> {
  String _query = '';
  String? _typeFilter;
  String _unitFilter = 'Tous';
  int? _statusFilterId;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);
    final types = ref.watch(itemTypesProvider).valueOrNull ?? const [];
    final group = ref.watch(accountControllerProvider).valueOrNull;
    final groupUnits = group?.units ?? const <GroupUnit>[];
    final statuses = sortedItemStatuses(
      group?.tentStatuses ?? const <TentStatusRef>[],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Matériel')),
      body: SafeArea(
        child: itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (items) {
            final selectedStatus = _statusFilterId == null
                ? null
                : statuses.where((s) => s.id == _statusFilterId).firstOrNull;
            final q = _query.trim().toLowerCase();

            final filtered = items.where((item) {
              final type = itemTypeByKey(types, item.typeKey);
              final unitName = _unitName(groupUnits, item.uniteId);
              final matchQuery =
                  q.isEmpty ||
                  item.nom.toLowerCase().contains(q) ||
                  (type?.name.toLowerCase().contains(q) ?? false) ||
                  unitName.toLowerCase().contains(q);
              final matchType =
                  _typeFilter == null || item.typeKey == _typeFilter;
              final matchStatus =
                  selectedStatus == null ||
                  item.statusId == selectedStatus.id ||
                  itemDisplayStatus(item, statuses).label.toLowerCase() ==
                      selectedStatus.name.trim().toLowerCase();
              final matchUnit =
                  _unitFilter == 'Tous' || unitName == _unitFilter;
              return matchQuery && matchType && matchStatus && matchUnit;
            }).toList();

            final usedTypes =
                {for (final item in items) item.typeKey}
                    .map((key) => itemTypeByKey(types, key))
                    .whereType<ItemType>()
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

            return Column(
              children: [
                // ---------- Fixed Header ----------
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  color: Colors.white,
                  child: Column(
                    spacing: 10,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher du matériel…',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      ExpandablePanel(
                        header: const Center(
                          child: Text('Affiner la recherche'),
                        ),
                        collapsed: const SizedBox.shrink(),
                        expanded: Column(
                          spacing: 10,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    isExpanded: true,
                                    initialValue:
                                        usedTypes.any(
                                          (t) => t.key == _typeFilter,
                                        )
                                        ? _typeFilter
                                        : null,
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Tous'),
                                      ),
                                      ...usedTypes.map(
                                        (t) => DropdownMenuItem<String?>(
                                          value: t.key,
                                          child: Text(
                                            t.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _typeFilter = v),
                                    decoration: const InputDecoration(
                                      labelText: 'Type',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    isExpanded: true,
                                    initialValue: selectedStatus?.id,
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Tous les statuts'),
                                      ),
                                      ...statuses.map(
                                        (e) => DropdownMenuItem<int?>(
                                          value: e.id,
                                          child: Text(e.name),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _statusFilterId = v),
                                    decoration: const InputDecoration(
                                      labelText: 'Statut',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _unitFilter,
                              items:
                                  <String>{
                                        'Tous',
                                        'Aucune unité',
                                        ...groupUnits.map((u) => u.name),
                                      }
                                      .map(
                                        (name) => DropdownMenuItem(
                                          value: name,
                                          child: Text(name),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) =>
                                  setState(() => _unitFilter = v ?? 'Tous'),
                              decoration: const InputDecoration(
                                labelText: 'Unité',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${filtered.length} / ${items.length} objets',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ---------- Scrollable List ----------
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(itemsProvider.notifier).reload(),
                    child: filtered.isEmpty
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  items.isEmpty
                                      ? 'Aucun matériel pour l\'instant.\n'
                                            'Ajoutez-en avec le bouton +.'
                                      : 'Aucun matériel ne correspond.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(top: 8, bottom: 80),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: GestureDetector(
                                  onLongPress: () => _showItemContextMenu(
                                    context,
                                    item,
                                    groupUnits,
                                    statuses,
                                  ),
                                  child: ItemCard(item: item),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajouter du matériel',
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddItemDialog(units: groupUnits, statuses: statuses),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showItemContextMenu(
    BuildContext context,
    Item item,
    List<GroupUnit> units,
    List<TentStatusRef> statuses,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                item.nom,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Dupliquer ce matériel'),
              subtitle: const Text(
                'Copie tous les attributs, nom à renseigner',
              ),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => AddItemDialog(
                    units: units,
                    statuses: statuses,
                    sourceItem: item,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: const Text('Signaler un problème'),
              onTap: () {
                Navigator.pop(ctx);
                showIssueDialog(
                  context,
                  target: IssueTarget.item(item.id),
                  targetName: item.nom,
                  maxQuantity: item.quantity,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static String _unitName(List<GroupUnit> units, int? uniteId) {
    for (final u in units) {
      if (int.tryParse(u.id) == uniteId) return u.name;
    }
    return 'Aucune unité';
  }
}

// ---------- Dialog d'ajout / duplication ----------
class AddItemDialog extends ConsumerStatefulWidget {
  final List<GroupUnit> units;
  final List<TentStatusRef> statuses;
  final Item? sourceItem;

  const AddItemDialog({
    super.key,
    required this.units,
    required this.statuses,
    this.sourceItem,
  });

  @override
  ConsumerState<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<AddItemDialog> {
  late final TextEditingController nomCtl;
  late final TextEditingController quantityCtl;
  late final TextEditingController thresholdCtl;

  String? typeKey;
  TentStatusRef? status;
  GroupUnit? selectedUnit;
  bool consumable = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final source = widget.sourceItem;
    // Le nom est toujours vide (à saisir), même en duplication.
    nomCtl = TextEditingController();
    quantityCtl = TextEditingController(text: '${source?.quantity ?? 1}');
    thresholdCtl = TextEditingController(
      text: source?.threshold?.toString() ?? '',
    );
    typeKey = source?.typeKey;
    consumable = source?.isConsumable ?? false;
    status =
        widget.statuses.where((s) => s.id == source?.statusId).firstOrNull ??
        widget.statuses.firstOrNull;
    selectedUnit = widget.units
        .where((u) => int.tryParse(u.id) == source?.uniteId)
        .firstOrNull;
  }

  @override
  void dispose() {
    nomCtl.dispose();
    quantityCtl.dispose();
    thresholdCtl.dispose();
    super.dispose();
  }

  void _onTypeChanged(ItemType? type) {
    setState(() {
      typeKey = type?.key;
      if (type == null) return;
      // Le mode de suivi du type donne les valeurs par défaut.
      consumable = type.tracking == ItemTracking.consumable;
      if (type.tracking == ItemTracking.piece) quantityCtl.text = '1';
    });
  }

  Future<void> _save() async {
    if (nomCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nom obligatoire')));
      return;
    }
    if (typeKey == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Type obligatoire')));
      return;
    }

    setState(() => isSaving = true);
    final source = widget.sourceItem;
    final item = Item(
      id: -1,
      typeKey: typeKey!,
      nom: nomCtl.text.trim(),
      quantity: (int.tryParse(quantityCtl.text.trim()) ?? 1).clamp(0, 100000),
      statusId: status?.id,
      uniteId: int.tryParse(selectedUnit?.id ?? ''),
      isConsumable: consumable,
      threshold: consumable ? int.tryParse(thresholdCtl.text.trim()) : null,
      localisation: source?.localisation ?? '',
      equipe: source?.equipe ?? '',
      colors: source?.colors ?? const [],
      fields: source?.fields ?? const {},
    );
    try {
      await ref.read(itemsProvider.notifier).createItem(item);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ajout impossible : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = [...ref.watch(itemTypesProvider).valueOrNull ?? const <ItemType>[]]
      ..sort((a, b) {
        final byFamily = a.family.compareTo(b.family);
        return byFamily != 0 ? byFamily : a.name.compareTo(b.name);
      });
    final selectedType = itemTypeByKey(types, typeKey ?? '');

    return AlertDialog(
      title: Text(
        widget.sourceItem != null
            ? 'Dupliquer "${widget.sourceItem!.nom}"'
            : 'Nouveau matériel',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomCtl,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<ItemType>(
              initialValue: selectedType,
              isExpanded: true,
              items: types
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        '${t.name} · ${t.family}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _onTypeChanged,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: quantityCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantité'),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              initialValue: status?.id,
              items: widget.statuses
                  .map(
                    (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                status = widget.statuses.where((e) => e.id == v).firstOrNull;
              }),
              decoration: const InputDecoration(labelText: 'Statut'),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<GroupUnit?>(
              initialValue: selectedUnit,
              items: [
                const DropdownMenuItem<GroupUnit?>(
                  value: null,
                  child: Text('Aucune unité préférée'),
                ),
                ...widget.units.map(
                  (e) => DropdownMenuItem<GroupUnit?>(
                    value: e,
                    child: Text(
                      e.name,
                      style: TextStyle(color: Color(e.color)),
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => selectedUnit = v),
              decoration: const InputDecoration(labelText: 'Unité'),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              value: consumable,
              onChanged: (v) => setState(() => consumable = v),
              title: const Text('Consommable'),
              contentPadding: EdgeInsets.zero,
            ),
            if (consumable)
              TextField(
                controller: thresholdCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seuil de rachat',
                  helperText: 'Alerte « À racheter » à partir de ce stock',
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          child: Text(
            isSaving
                ? (widget.sourceItem != null ? 'Duplication...' : 'Ajout...')
                : (widget.sourceItem != null ? 'Dupliquer' : 'Ajouter'),
          ),
        ),
      ],
    );
  }
}

/// Statuts du groupe non archivés, dans l'ordre choisi (comme les tentes).
List<TentStatusRef> sortedItemStatuses(List<TentStatusRef> statuses) {
  final seenIds = <int>{};
  final out = <TentStatusRef>[];
  for (final status in statuses) {
    if (status.isArchived) continue;
    if (seenIds.add(status.id)) out.add(status);
  }
  out.sort((a, b) {
    final byOrder = a.order.compareTo(b.order);
    return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
  });
  return out;
}
