import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/domain/entities/unit.dart';
import 'package:logistiscout/ui/controllers/controle_controller.dart';
import 'package:logistiscout/ui/controllers/tentes_controller.dart';
import 'package:logistiscout/ui/pages/controle_detail_page.dart';
import 'package:logistiscout/ui/pages/controle_edit_page.dart';
import 'package:logistiscout/ui/pages/controle_saisie_nom_page.dart';
import 'package:logistiscout/ui/pages/evenement_detail/evenement_detail_page.dart';

class TenteDetailPage extends ConsumerStatefulWidget {
  final int tenteId;
  const TenteDetailPage({super.key, required this.tenteId});

  @override
  ConsumerState<TenteDetailPage> createState() => _TenteDetailPageState();
}

class _TenteDetailPageState extends ConsumerState<TenteDetailPage> {
  // nullable controllers (init lazily when data available)
  TextEditingController? _nomCtl;
  TextEditingController? _nbCtl;
  TextEditingController? _couleursCtl;
  TextEditingController? _remarquesCtl;

  // local editable state (nullable until we see data)
  String? _typeTente;
  TentState? _etat;
  bool? _estIntegree;
  List<String>? _couleursHex;
  Unit? _unitePreferee;

  static const _types = ['Canadienne', 'Tipi', 'Marabout', 'Autre'];

  void _ensureControllersAndState(Tent t) {
    _nomCtl ??= TextEditingController(text: t.nom);
    _nbCtl ??= TextEditingController(text: t.nbPlaces.toString());
    _remarquesCtl ??= TextEditingController(text: t.comments);

    _typeTente ??= (_types.contains(t.tentType) ? t.tentType : 'Autre');
    _etat ??= t.state;
    _estIntegree ??= t.isFloorEmbedded;
    _unitePreferee ??= Unit.fromString(t.assignedUnit);

    _couleursHex ??= List<String>.from(t.colors);
  }

  @override
  void dispose() {
    _nomCtl?.dispose();
    _nbCtl?.dispose();
    _couleursCtl?.dispose();
    _remarquesCtl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tentesAsync = ref.watch(tentesProvider);
    final controlesAsync = ref.watch(controleProvider(widget.tenteId));
    final evenementsAsync = ref.watch(evenementsParTenteProvider(widget.tenteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail tente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: () async {
              await ref.read(tentesProvider.notifier).reload();
              await ref.read(controleProvider(widget.tenteId).notifier).reload();
            },
          ),
        ],
      ),
      body: tentesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (tentes) {
          final tente = tentes.where((t) => t.id == widget.tenteId).cast<Tent?>().firstOrNull;
          if (tente == null) {
            return const Center(child: Text('Tente introuvable.'));
          }

          _ensureControllersAndState(tente);

          return controlesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur chargement contrôles : $e')),
            data: (controles) {
              final dernierControle = controles.isNotEmpty ? controles.last : null;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _HeaderCard(tente: tente),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        // --- Informations générales ---
                        _SectionCard(
                          title: 'Informations générales',
                          action: IconButton(
                            tooltip: 'Enregistrer',
                            icon: const Icon(Icons.save, color: Colors.blueAccent),
                            onPressed: () async {
                              final updated = tente.copyWith(
                                nom: _nomCtl!.text.trim(),
                                nbPlaces: int.tryParse(_nbCtl!.text) ?? tente.nbPlaces,
                                tentType: _typeTente!,
                                state: _etat!,
                                isFloorEmbedded: _estIntegree!,
                                colors: _couleursHex!,
                                assignedUnit: _unitePreferee!.name,
                              );
                              await ref.read(tentesProvider.notifier).updateTente(updated);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Informations générales enregistrées')),
                                );
                              }
                            },
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _nomCtl,
                                decoration: const InputDecoration(
                                  labelText: 'Nom',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _nbCtl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Capacité (nb places)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _types.contains(_typeTente!) ? _typeTente : 'Autre',
                                      items: _types
                                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                          .toList(),
                                      onChanged: (v) => setState(() => _typeTente = v ?? 'Autre'),
                                      decoration: const InputDecoration(
                                        labelText: 'Type de tente',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              DropdownButtonFormField<TentState>(
                                initialValue: _etat!,
                                items: TentState.values
                                    .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(tentStateToString(e)),
                                ))
                                    .toList(),
                                onChanged: (v) => setState(() => _etat = v ?? TentState.broken),
                                decoration: const InputDecoration(
                                  labelText: 'État',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 15),
                              DropdownButtonFormField<Unit>(
                                initialValue: _unitePreferee!,
                                items: Unit.values
                                    .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name),
                                ))
                                    .toList(),
                                onChanged: (v) => setState(() => _unitePreferee = v),
                                decoration: const InputDecoration(
                                  labelText: 'Unité',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 15),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Tapis de sol intégré'),
                                value: _estIntegree!,
                                onChanged: (v) => setState(() => _estIntegree = v),
                              ),
                              const SizedBox(height: 4),
                              _RowLabel('Couleurs'),
                              const SizedBox(height: 6),
                              _ColorChipsEditor(
                                colorsHex: _couleursHex!,
                                onAdd: (hex) => setState(() => _couleursHex!.add(hex)),
                                onRemove: (hex) => setState(() => _couleursHex!.remove(hex)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --- Dernier contrôle ---
                        if (dernierControle != null)
                          _SectionCard(
                            title: 'Dernier contrôle',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.assignment_turned_in, color: Colors.blue),
                              ),
                              title: Text(
                                'Contrôle du ${_fmtDate(dernierControle.date)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                dernierControle.comment.isNotEmpty
                                    ? 'Remarques : ${dernierControle.comment}'
                                    : 'Aucune remarque',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ControleDetailPage(
                                      controle: dernierControle,
                                      tente: tente,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 16),

                        // --- Historique des sorties (Événements) ---
                        evenementsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Erreur chargement événements : $e'),
                          data: (evenements) {
                            if (evenements.isEmpty) {
                              return const _SectionCard(
                                title: 'Historique des sorties',
                                child: Text('Aucune sortie enregistrée pour cette tente.'),
                              );
                            }

                            return _SectionCard(
                              title: 'Historique des sorties',
                              child: Column(
                                children: evenements.map((evt) {
                                  final enCours = evt.dateFin.isAfter(DateTime.now());
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: enCours ? Colors.green.shade100 : Colors.blue.shade100,
                                      child: Icon(
                                        enCours ? Icons.campaign : Icons.event_available,
                                        color: enCours ? Colors.green.shade800 : Colors.blue.shade800,
                                      ),
                                    ),
                                    title: Text(evt.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      '${_fmtDate(evt.date)}'
                                          '${' → ${_fmtDate(evt.dateFin)}'}',
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EvenementDetailPage(eventId: evt.id.toString()),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),


                        const SizedBox(height: 16),

                        // --- Remarques ---
                        _SectionCard(
                          title: 'Remarques',
                          child: Column(
                            children: [
                              TextField(
                                controller: _remarquesCtl,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Notes sur la tente…',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.save),
                                  label: const Text('Enregistrer la remarque'),
                                  onPressed: () async {
                                    final updated = tente.copyWith(
                                      comment: _remarquesCtl!.text.trim(),
                                    );
                                    await ref.read(tentesProvider.notifier).updateTente(updated);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Remarques enregistrées')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80), // space for bottom buttons
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
                                    builder: (_) => ControleSaisieNomPage(
                                      onNomValide: (nomControleur) async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ControleEditPage(
                                              tente: tente,
                                              nomControleur: nomControleur,
                                            ),
                                          ),
                                        );
                                        await ref.read(controleProvider(tente.id).notifier).reload();
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
                                    content: Text('Supprimer « ${tente.nom} » ? Cette action est irréversible.'),
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
                                if (confirm == true) {
                                  await ref.read(tentesProvider.notifier).deleteTente(tente.id);
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
          );
        },
      ),

    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

}

class _ColorChipsEditor extends StatelessWidget {
  final List<String> colorsHex;
  final void Function(String hex) onAdd;
  final void Function(String hex) onRemove;

  const _ColorChipsEditor({
    required this.colorsHex,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // existing colors as removable chips
        ...colorsHex.map((hex) {
          final color = _parseHexColor(hex);
          return Chip(
            label: Text(
              hex.toUpperCase(),
              style: TextStyle(
                color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            backgroundColor: color,
            deleteIcon: const Icon(Icons.close),
            onDeleted: () => onRemove(hex),
          );
        }),

        // "+" add button
        _AddColorButton(onPick: (color) {
          final hex = _toHex(color);
          if (!colorsHex.contains(hex)) {
            onAdd(hex);
          }
        }),
      ],
    );
  }

  static Color _parseHexColor(String hex) {
    try {
      final h = hex.startsWith('#') ? hex.substring(1) : hex;
      return Color(int.parse(h, radix: 16) + 0xFF000000);
    } catch (_) {
      return Colors.grey.shade400;
    }
  }

  static String _toHex(Color c) {
    final v = (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    return '#$v';
    // If you want ARGB: return '#${c.value.toRadixString(16).padLeft(8,'0').toUpperCase()}';
  }
}

class _AddColorButton extends StatelessWidget {
  final void Function(Color) onPick;
  const _AddColorButton({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        Color temp = Colors.blue;
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Choisir une couleur'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: temp,
                onColorChanged: (c) => temp = c,
                enableAlpha: false,
                pickerAreaHeightPercent: 0.7,
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text('Ajouter'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
        if (ok == true) {
          onPick(temp);
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(19),
          color: Colors.white,
        ),
        child: const Icon(Icons.add, size: 22),
      ),
    );
  }
}


class _RowLabel extends StatelessWidget {
  final String text;
  const _RowLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Tent tente;
  const _HeaderCard({required this.tente});

  @override
  Widget build(BuildContext context) {
    final chipColor = _chipColor(tente.state);

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(Unit.fromString(tente.assignedUnit).color),
              child: const Icon(Icons.cabin, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tente.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: chipColor.withAlpha(30),
                          border: Border.all(color: chipColor.withAlpha(80)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tentStateToString(tente.state),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
                  if (tente.colors.isNotEmpty) ...[
                    const SizedBox(height: 8),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _chipColor(TentState e) {
    switch (e) {
      case TentState.good :
        return Colors.green.shade700;
      case TentState.broken:
        return Colors.orange.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  static Color _parseColor(String s) {
    try {
      if (s.startsWith('#')) {
        return Color(int.parse(s.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return Colors.grey.shade400;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action; // 👈 add this

  const _SectionCard({
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( // 👈 title + action icon aligned
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

// tiny helper for firstOrNull
extension _IterableX<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
