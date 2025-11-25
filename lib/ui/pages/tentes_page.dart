import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/entities/unit.dart';
import 'package:logistiscout/ui/controllers/tentes_controller.dart';
import 'package:logistiscout/ui/pages/tente_detail_page.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentes'),
      ),
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
              final matchType =
              _typeFilter == 'Tous' ? true : t.tentType == _typeFilter;
              final matchEtat = _etatFilter == null ? true : t.state == _etatFilter;
              final matchSize = _sizeFilter == 'Tous' ? true : t.nbPlaces.toString() == _sizeFilter;
              final matchUnit = _unitFilter == 'Tous' ? true : t.assignedUnit == _unitFilter;
              return matchQuery && matchType && matchEtat && matchSize && matchUnit;
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
                        expanded:Column(
                          spacing: 10,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Expanded(
                                  child: _TypeFilter(
                                    value: _typeFilter,
                                    onChanged: (v) => setState(() => _typeFilter = v),
                                  ),
                                ),
                                Expanded(
                                  child: _EtatFilter(
                                    value: _etatFilter,
                                    onChanged: (v) => setState(() => _etatFilter = v),
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
                                    onChanged: (v) => setState(() => _sizeFilter = v),
                                  ),
                                ),
                                Expanded(
                                  child: _UnitFilter(
                                    value: _unitFilter,
                                    onChanged: (v) => setState(() => _unitFilter = v),
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
                          child: _TenteCard(
                            tente: t,
                            onOpen: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TenteDetailPage(tenteId: t.id),
                                ),
                              );
                              ref.read(tentesProvider.notifier).reload();
                            },
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
        onPressed: () => _showAddTenteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---------- Dialog d’ajout ----------
  void _showAddTenteDialog(BuildContext context, WidgetRef ref) {
    final nomCtl = TextEditingController();
    final nbCtl = TextEditingController(text: '6');
    final couleursCtl = TextEditingController();
    String type = 'Canadienne';
    var etat = TentState.broken; // défaut demandé
    var integree = false;
    Unit unitePreferee = Unit.tous;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
                  DropdownMenuItem(value: 'Canadienne', child: Text('Canadienne')),
                  DropdownMenuItem(value: 'Tipi', child: Text('Tipi')),
                  DropdownMenuItem(value: 'Marabout', child: Text('Marabout')),
                  DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                ],
                onChanged: (v) => type = v ?? 'Canadienne',
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
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(tentStateToString(e)),
                ))
                    .toList(),
                onChanged: (v) => etat = v ?? TentState.broken,
                decoration: const InputDecoration(labelText: 'État'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Unit>(
                initialValue: unitePreferee,
                items: Unit.values
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.name, style: TextStyle(color: Color(e.color)),),
                ))
                    .toList(),
                onChanged: (v) => unitePreferee = v ?? Unit.tous,
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
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Ajouter'),
            onPressed: () async {
              if (nomCtl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nom obligatoire')),
                );
                return;
              }

              final newTente = Tent(
                id: -1,
                nom: nomCtl.text.trim(),
                uniteId: null,
                state: etat,
                comment: '',
                isFloorEmbedded: integree,
                nbPlaces: int.tryParse(nbCtl.text) ?? 0,
                tentType: type,
                assignedUnit: unitePreferee.name,
                agenda: const [],
                controlHistory: const [],
                colors: couleursCtl.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                groupId: '',
              );

              await ref.read(tentesProvider.notifier).createTente(newTente);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ======= Widgets & helpers UI =======

class _TenteCard extends StatelessWidget {
  final Tent tente;
  final VoidCallback onOpen;
  const _TenteCard({required this.tente, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final bg = _etatBgColor(tente.state);
    final chipColor = _etatChipColor(tente.state);

    return Card(
      elevation: 2,
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(Unit.fromString(tente.assignedUnit).color),
                child: const Icon(Icons.cabin, color: Colors.white),
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + état chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tente.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: chipColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: chipColor.withAlpha(80)),
                          ),
                          child: Text(
                            tentStateToString(tente.state),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: chipColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tente.tentType} • ${tente.nbPlaces} places'
                          '${tente.assignedUnit.isNotEmpty ? ' • ${tente.assignedUnit}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    // Bandeau de petites pastilles couleur scotch
                    if (tente.colors.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: tente.colors.take(6).map((c) {
                          return Container(
                            width: 16,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _parseColor(c),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _UnitFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {

    return DropdownButtonFormField<Unit>(
      isExpanded: true,
      initialValue: Unit.tous,
      items: Unit.values
          .map((t) => DropdownMenuItem(value: t, child: Text(t.name, style: TextStyle(color: Color(t.color)))))
          .toList(),
      onChanged: (v) => onChanged(v?.name ?? 'Non affectée'),
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
    const sizes = ["Tous","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15"];
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

Color _etatBgColor(TentState e) {
  switch (e) {
    case TentState.good:
      return Colors.green.shade50;
    case TentState.broken:
      return Colors.orange.shade50;
    default:
      return Colors.red.shade50;
  }
}

Color _etatChipColor(TentState e) {
  switch (e) {
    case TentState.good:
      return Colors.green.shade700;
    case TentState.broken:
      return Colors.orange.shade700;
    default:
      return Colors.red.shade700;
  }
}

Color _parseColor(String s) {
  try {
    if (s.startsWith('#')) {
      return Color(int.parse(s.substring(1), radix: 16) + 0xFF000000);
    }
    return Colors.grey.shade400;
  } catch (_) {
    return Colors.grey.shade400;
  }
}
