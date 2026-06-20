import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/services/tent_import_service.dart';
import 'package:logistiscout/ui/controllers/tentes_controller.dart';
import 'package:logistiscout/ui/widgets/common/tent_card.dart';

class TentesPage extends ConsumerStatefulWidget {
  const TentesPage({super.key});

  @override
  ConsumerState<TentesPage> createState() => _TentesPageState();
}

class _TentesPageState extends ConsumerState<TentesPage> {
  String _query = '';
  String _typeFilter = 'Tous';
  String _sizeFilter = 'Tous';
  String _unitFilter = 'Tous';
  int? _statusFilterId;

  @override
  Widget build(BuildContext context) {
    final tentesAsync = ref.watch(tentesProvider);
    final group = ref.watch(accountControllerProvider).valueOrNull;
    final groupUnits = group?.units ?? const <GroupUnit>[];
    final statuses = _sortedStatuses(
      group?.tentStatuses ?? const <TentStatusRef>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Importer depuis Excel',
            onPressed: () =>
                _importFromExcel(context, groupUnits, statuses),
          ),
        ],
      ),
      body: SafeArea(
        child: tentesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (tentes) {
            // Filtres
            final filtered = tentes.where((t) {
              final unitLabel = t.assignedUnit.trim().isEmpty
                  ? 'Aucune unité'
                  : t.assignedUnit;
              final q = _query.trim().toLowerCase();
              final matchQuery = q.isEmpty
                  ? true
                  : t.nom.toLowerCase().contains(q) ||
                        t.tentType.toLowerCase().contains(q) ||
                        unitLabel.toLowerCase().contains(q);
              final matchType = _typeFilter == 'Tous'
                  ? true
                  : t.tentType == _typeFilter;
              final selectedStatus = _statusFilterId == null
                  ? null
                  : _firstStatusById(statuses, _statusFilterId);
              final matchStatus = selectedStatus == null
                  ? true
                  : t.tentStatusId == selectedStatus.id ||
                        t.displayStatusLabel.trim().toLowerCase() ==
                            selectedStatus.name.trim().toLowerCase();
              final matchSize = _sizeFilter == 'Tous'
                  ? true
                  : t.nbPlaces.toString() == _sizeFilter;
              final matchUnit = _unitFilter == 'Tous'
                  ? true
                  : unitLabel == _unitFilter;
              return matchQuery &&
                  matchType &&
                  matchStatus &&
                  matchSize &&
                  matchUnit;
            }).toList();

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
                          hintText: 'Rechercher une tente…',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      ExpandablePanel(
                        header: Center(child: Text("Affiner la recherche")),
                        collapsed: const SizedBox.shrink(),
                        expanded: Column(
                          spacing: 10,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Expanded(
                                  child: _TypeFilter(
                                    value: _typeFilter,
                                    onChanged: (v) =>
                                        setState(() => _typeFilter = v),
                                  ),
                                ),
                                Expanded(
                                  child: _EtatFilter(
                                    value: _statusFilterId,
                                    statuses: statuses,
                                    onChanged: (v) =>
                                        setState(() => _statusFilterId = v),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              spacing: 8,
                              children: [
                                Expanded(
                                  child: _SizeFilter(
                                    value: _sizeFilter,
                                    onChanged: (v) =>
                                        setState(() => _sizeFilter = v),
                                  ),
                                ),
                                Expanded(
                                  child: _UnitFilter(
                                    value: _unitFilter,
                                    units: groupUnits,
                                    onChanged: (v) =>
                                        setState(() => _unitFilter = v),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ---------- Scrollable List ----------
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(tentesProvider.notifier).reload(),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = filtered[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GestureDetector(
                            onLongPress: () => _showTentContextMenu(
                              context,
                              t,
                              groupUnits,
                              statuses,
                            ),
                            child: TentCard(tent: t),
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
        tooltip: 'Ajouter une tente',
        onPressed: () => _showAddTenteDialog(context, groupUnits, statuses),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTenteDialog(
    BuildContext context,
    List<GroupUnit> units,
    List<TentStatusRef> statuses,
  ) {
    showDialog(
      context: context,
      builder: (_) => AddTenteDialog(units: units, statuses: statuses),
    );
  }

  void _showTentContextMenu(
    BuildContext context,
    Tent tent,
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
                tent.nom,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Dupliquer cette tente'),
              subtitle: const Text('Copie tous les attributs, nom à renseigner'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => AddTenteDialog(
                    units: units,
                    statuses: statuses,
                    sourceTent: tent,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromExcel(
    BuildContext context,
    List<GroupUnit> units,
    List<TentStatusRef> statuses,
  ) async {
    final rows = await TentImportService.pickAndParse();
    if (rows == null) return;
    if (!context.mounted) return;

    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le fichier Excel est vide ou invalide.')),
      );
      return;
    }

    final result = TentImportService.buildTents(
      rows: rows,
      units: units,
      statuses: statuses,
    );

    if (result.tents.isEmpty && result.errors.isNotEmpty) {
      if (!context.mounted) return;
      _showImportReport(context, result, 0);
      return;
    }

    // Confirmation avant création
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer l\'import'),
        content: Text(
          '${result.tents.length} tente(s) seront créées.'
          '${result.errors.isNotEmpty ? '\n\n${result.errors.length} avertissement(s) détecté(s).' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    int created = 0;
    final creationErrors = <String>[];

    for (final tent in result.tents) {
      try {
        await ref.read(tentesProvider.notifier).createTente(tent);
        created++;
      } catch (e) {
        creationErrors.add('${tent.nom} : $e');
      }
    }

    if (!context.mounted) return;
    _showImportReport(
      context,
      TentImportResult(
        tents: result.tents.take(created).toList(),
        errors: [...result.errors, ...creationErrors],
      ),
      created,
    );
  }

  void _showImportReport(
    BuildContext context,
    TentImportResult result,
    int created,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Résultat de l\'import'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ $created tente(s) créée(s).'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('⚠️ ${result.errors.length} avertissement(s) :'),
                const SizedBox(height: 4),
                ...result.errors.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      '• $e',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ---------- Dialog d’ajout / duplication ----------
class AddTenteDialog extends ConsumerStatefulWidget {
  final List<GroupUnit> units;
  final List<TentStatusRef> statuses;
  final Tent? sourceTent;

  const AddTenteDialog({
    super.key,
    required this.units,
    required this.statuses,
    this.sourceTent,
  });

  @override
  ConsumerState<AddTenteDialog> createState() => _AddTenteDialogState();
}

class _AddTenteDialogState extends ConsumerState<AddTenteDialog> {
  late final TextEditingController nomCtl;
  late final TextEditingController nbCtl;
  late final TextEditingController couleursCtl;

  String type = 'Canadienne';
  TentStatusRef? status;
  bool integree = false;
  GroupUnit? selectedUnit;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final source = widget.sourceTent;
    // Le nom est toujours vide (à saisir), même en duplication.
    nomCtl = TextEditingController();
    nbCtl = TextEditingController(
      text: source != null ? source.nbPlaces.toString() : '6',
    );
    couleursCtl = TextEditingController(
      text: source?.colors.join(', ') ?? '',
    );
    type = source?.tentType ?? 'Canadienne';
    integree = source?.isFloorEmbedded ?? false;

    if (source != null) {
      selectedUnit = widget.units.cast<GroupUnit?>().firstWhere(
        (u) => int.tryParse(u!.id) == source.uniteId,
        orElse: () => null,
      );
      status = widget.statuses.cast<TentStatusRef?>().firstWhere(
        (s) => s!.id == source.tentStatusId,
        orElse: () => null,
      );
      status ??= widget.statuses.isNotEmpty ? widget.statuses.first : null;
    } else {
      selectedUnit = null;
      status = widget.statuses.isNotEmpty ? widget.statuses.first : null;
    }
  }

  @override
  void dispose() {
    nomCtl.dispose();
    nbCtl.dispose();
    couleursCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.sourceTent != null
            ? 'Dupliquer "${widget.sourceTent!.nom}"'
            : 'Nouvelle tente',
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

            DropdownButtonFormField<String>(
              initialValue: type,
              items: const [
                DropdownMenuItem(
                  value: 'Canadienne',
                  child: Text('Canadienne'),
                ),
                DropdownMenuItem(value: 'Tipi', child: Text('Tipi')),
                DropdownMenuItem(value: 'Marabout', child: Text('Marabout')),
                DropdownMenuItem(value: 'Autre', child: Text('Autre')),
              ],
              onChanged: (v) => setState(() => type = v ?? 'Canadienne'),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: nbCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nombre de places'),
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
                status = widget.statuses
                    .where((e) => e.id == v)
                    .cast<TentStatusRef?>()
                    .firstOrNull;
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
              value: integree,
              onChanged: (v) => setState(() => integree = v),
              title: const Text('Tapis de sol intégré'),
              contentPadding: EdgeInsets.zero,
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
          onPressed: isSaving
              ? null
              : () async {
                  if (nomCtl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nom obligatoire')),
                    );
                    return;
                  }

                  setState(() => isSaving = true);

                  final newTente = Tent(
                    id: -1,
                    nom: nomCtl.text.trim(),
                    uniteId: int.tryParse(selectedUnit?.id ?? ''),
                    state: tentStateFromString(status?.name ?? 'Bon'),
                    tentStatusId: status?.id,
                    tentStatusLabel: status?.name,
                    tentStatusColor: status?.color,
                    comment: '',
                    isFloorEmbedded: integree,
                    nbPlaces: int.tryParse(nbCtl.text) ?? 0,
                    tentType: type,
                    assignedUnit: selectedUnit?.name ?? '',
                    agenda: const [],
                    controlHistory: const [],
                    colors: couleursCtl.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                    groupId: '0',
                    team: '',
                    location: '',
                  );

                  await ref.read(tentesProvider.notifier).createTente(newTente);

                  if (mounted) Navigator.pop(context);
                },
          child: Text(
            isSaving
                ? (widget.sourceTent != null ? 'Duplication...' : 'Ajout...')
                : (widget.sourceTent != null ? 'Dupliquer' : 'Ajouter'),
          ),
        ),
      ],
    );
  }
}

// ======= Widgets & helpers UI =======

class _UnitFilter extends StatelessWidget {
  final String value;
  final List<GroupUnit> units;
  final ValueChanged<String> onChanged;

  const _UnitFilter({
    required this.value,
    required this.units,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final unitNames = <String>{
      'Tous',
      'Aucune unité',
      ...units.map((u) => u.name),
    }.toList();

    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: unitNames.contains(value) ? value : 'Tous',
      items: unitNames
          .map((name) => DropdownMenuItem(value: name, child: Text(name)))
          .toList(),
      onChanged: (v) => onChanged(v ?? 'Tous'),
      decoration: const InputDecoration(
        labelText: 'Unité',
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _SizeFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SizeFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const sizes = [
      "Tous",
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "8",
      "9",
      "10",
      "11",
      "12",
      "13",
      "14",
      "15",
    ];
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: sizes.contains(value) ? value : 'Tous',
      items: sizes
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (v) => onChanged(v ?? 'Tous'),
      decoration: const InputDecoration(
        labelText: 'Taille',
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _TypeFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const types = ['Tous', 'Canadienne', 'Tipi', 'Marabout', 'Autre'];
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: types.contains(value) ? value : 'Tous',
      items: types
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (v) => onChanged(v ?? 'Tous'),
      decoration: const InputDecoration(
        labelText: 'Type',
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _EtatFilter extends StatelessWidget {
  final int? value;
  final List<TentStatusRef> statuses;
  final ValueChanged<int?> onChanged;

  const _EtatFilter({
    required this.value,
    required this.statuses,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      isExpanded: true,
      initialValue: value,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Tous les statuts'),
        ),
        ...statuses.map(
          (e) => DropdownMenuItem<int?>(value: e.id, child: Text(e.name)),
        ),
      ],
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Statut',
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );
  }
}

TentStatusRef? _firstStatusById(List<TentStatusRef> statuses, int? id) {
  if (id == null) return null;
  for (final status in statuses) {
    if (status.id == id) return status;
  }
  return null;
}

List<TentStatusRef> _sortedStatuses(List<TentStatusRef> statuses) {
  final seenIds = <int>{};
  final items = <TentStatusRef>[];
  for (final status in statuses) {
    if (status.isArchived) continue;
    if (seenIds.add(status.id)) {
      items.add(status);
    }
  }
  items.sort((a, b) {
    final byOrder = a.order.compareTo(b.order);
    if (byOrder != 0) return byOrder;
    return a.id.compareTo(b.id);
  });
  return items;
}
