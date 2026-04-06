import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/services/local_storage_service.dart';
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
  TentState? _etatFilter;

  @override
  Widget build(BuildContext context) {
    final tentesAsync = ref.watch(tentesProvider);
    final groupUnits =
        ref.watch(accountControllerProvider).valueOrNull?.units ??
        const <GroupUnit>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Tentes')),
      body: SafeArea(
        child: tentesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (tentes) {
            // Filtres
            final filtered = tentes.where((t) {
              final q = _query.trim().toLowerCase();
              final matchQuery = q.isEmpty
                  ? true
                  : t.nom.toLowerCase().contains(q) ||
                        t.tentType.toLowerCase().contains(q) ||
                        t.assignedUnit.toLowerCase().contains(q);
              final matchType = _typeFilter == 'Tous'
                  ? true
                  : t.tentType == _typeFilter;
              final matchEtat = _etatFilter == null
                  ? true
                  : t.state == _etatFilter;
              final matchSize = _sizeFilter == 'Tous'
                  ? true
                  : t.nbPlaces.toString() == _sizeFilter;
              final matchUnit = _unitFilter == 'Tous'
                  ? true
                  : t.assignedUnit == _unitFilter;
              return matchQuery &&
                  matchType &&
                  matchEtat &&
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
                                    value: _etatFilter,
                                    onChanged: (v) =>
                                        setState(() => _etatFilter = v),
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
                          child: TentCard(tent: t),
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
        onPressed: () => _showAddTenteDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTenteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddTenteDialog(
        units:
            ref.watch(accountControllerProvider).valueOrNull?.units ??
            const <GroupUnit>[],
      ),
    );
  }
}

// ---------- Dialog d’ajout ----------
class AddTenteDialog extends ConsumerStatefulWidget {
  final List<GroupUnit> units;

  const AddTenteDialog({super.key, required this.units});

  @override
  ConsumerState<AddTenteDialog> createState() => _AddTenteDialogState();
}

class _AddTenteDialogState extends ConsumerState<AddTenteDialog> {
  late final TextEditingController nomCtl;
  late final TextEditingController nbCtl;
  late final TextEditingController couleursCtl;

  String type = 'Canadienne';
  TentState etat = TentState.broken;
  bool integree = false;
  GroupUnit? selectedUnit;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nomCtl = TextEditingController();
    nbCtl = TextEditingController(text: '6');
    couleursCtl = TextEditingController();
    selectedUnit = widget.units.isNotEmpty ? widget.units.first : null;
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
      title: const Text('Nouvelle tente'),
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

            DropdownButtonFormField<TentState>(
              initialValue: etat,
              items: TentState.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(tentStateToString(e)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => etat = v ?? TentState.broken),
              decoration: const InputDecoration(labelText: 'État'),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<GroupUnit>(
              initialValue: selectedUnit,
              items: widget.units
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e.name,
                        style: TextStyle(color: Color(e.color)),
                      ),
                    ),
                  )
                  .toList(),
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
                    state: etat,
                    comment: '',
                    isFloorEmbedded: integree,
                    nbPlaces: int.tryParse(nbCtl.text) ?? 0,
                    tentType: type,
                    assignedUnit: selectedUnit?.name ?? 'Groupe',
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
          child: Text(isSaving ? 'Ajout...' : 'Ajouter'),
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
    final unitNames = <String>{'Tous', ...units.map((u) => u.name)}.toList();

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
  final TentState? value;
  final ValueChanged<TentState?> onChanged;

  const _EtatFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TentState?>(
      isExpanded: true,
      initialValue: value,
      items: [
        const DropdownMenuItem<TentState?>(
          value: null,
          child: Text('Tous les états'),
        ),
        ...TentState.values.map(
          (e) => DropdownMenuItem<TentState?>(
            value: e,
            child: Text(tentStateToString(e)),
          ),
        ),
      ],
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'État',
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );
  }
}
