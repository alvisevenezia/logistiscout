import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/tente.dart';
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
  String _unitFilter = 'Non affectée';
  EtatTente? _etatFilter;

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
                  t.typeTente.toLowerCase().contains(q) ||
                  t.unitePreferee.toLowerCase().contains(q);
              final matchType =
              _typeFilter == 'Tous' ? true : t.typeTente == _typeFilter;
              final matchEtat = _etatFilter == null ? true : t.etat == _etatFilter;
              final matchSize = _sizeFilter == 'Tous' ? true : t.nbPlaces.toString() == _sizeFilter;
              final matchUnit = _unitFilter == 'Non affectée' ? true : t.unitePreferee == _unitFilter;
              return matchQuery && matchType && matchEtat && matchSize && matchUnit;
            }).toList();

            return Column(
              children: [
                // ---------- Fixed Header ----------
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  color: Colors.white,
                  child: Column(
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
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _TypeFilter(
                                  value: _typeFilter,
                                  onChanged: (v) => setState(() => _typeFilter = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _EtatFilter(
                                  value: _etatFilter,
                                  onChanged: (v) => setState(() => _etatFilter = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _SizeFilter(
                                  value: _sizeFilter,
                                  onChanged: (v) => setState(() => _sizeFilter = v),
                                ),
                              ),
                              const SizedBox(width: 8),
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

                      const SizedBox(width: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${filtered.length} / ${tentes.length} tentes',
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
    var etat = EtatTente.casse; // défaut demandé
    var integree = false;
    String unitePreferee = '';

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
              DropdownButtonFormField<EtatTente>(
                initialValue: etat,
                items: EtatTente.values
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(etatTenteToString(e)),
                ))
                    .toList(),
                onChanged: (v) => etat = v ?? EtatTente.casse,
                decoration: const InputDecoration(labelText: 'État'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: integree,
                onChanged: (v) => setState(() => integree = v),
                title: const Text('Tapis de sol intégré'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: couleursCtl,
                decoration: const InputDecoration(
                  labelText: 'Couleurs (ex: #FF0000, #00FF00)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (v) => unitePreferee = v,
                decoration: const InputDecoration(
                  labelText: 'Unité préférée (optionnel)',
                ),
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

              final newTente = Tente(
                id: -1,
                nom: nomCtl.text.trim(),
                uniteId: null,
                etat: etat,
                remarques: '',
                tapisSolIntegre: integree,
                nbPlaces: int.tryParse(nbCtl.text) ?? 0,
                typeTente: type,
                unitePreferee: unitePreferee,
                agenda: const [],
                historiqueControles: const [],
                couleurs: couleursCtl.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                groupeId: '',
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
  final Tente tente;
  final VoidCallback onOpen;
  const _TenteCard({required this.tente, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final bg = _etatBgColor(tente.etat);
    final chipColor = _etatChipColor(tente.etat);

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
              // Avatar couleur principale
              CircleAvatar(
                radius: 22,
                backgroundColor: tente.couleurs.isNotEmpty
                    ? _parseColor(tente.couleurs.first)
                    : Colors.grey.shade400,
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
                            etatTenteToString(tente.etat),
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
                      '${tente.typeTente} • ${tente.nbPlaces} places'
                          '${tente.unitePreferee.isNotEmpty ? ' • ${tente.unitePreferee}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    // Bandeau de petites pastilles couleur scotch
                    if (tente.couleurs.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: tente.couleurs.take(6).map((c) {
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
    //TODO : fetch units from backend instead of hardcoding
    const units = const [
      'Non affectée',
      'Farfadets',
      'Louveteaux-Jeannettes',
      'Scouts-Guides',
      'Pionniers-Caravelles',
      'Compagnons',
      'Groupe'
    ];
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: units.contains(value) ? value : 'Non affectée',
      items: units
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (v) => onChanged(v ?? 'Non affectée'),
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
  final EtatTente? value;
  final ValueChanged<EtatTente?> onChanged;
  const _EtatFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {

    return DropdownButtonFormField<EtatTente?>(
      isExpanded: true,
      initialValue: value,
      items: [
        const DropdownMenuItem<EtatTente?>(
          value: null,
          child: Text('Tous les états'),
        ),
        ...EtatTente.values.map(
              (e) => DropdownMenuItem<EtatTente?>(
            value: e,
            child: Text(etatTenteToString(e)),
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

Color _etatBgColor(EtatTente e) {
  switch (e) {
    case EtatTente.ok:
      return Colors.green.shade50;
    case EtatTente.casse:
      return Colors.orange.shade50;
    default:
      return Colors.red.shade50;
  }
}

Color _etatChipColor(EtatTente e) {
  switch (e) {
    case EtatTente.ok:
      return Colors.green.shade700;
    case EtatTente.casse:
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
