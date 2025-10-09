import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/ui/controllers/evenement_controller.dart';
import 'package:logistiscout/ui/pages/evenement_detail_page.dart';
import '../controllers/tentes_controller.dart';

class EvenementsPage extends ConsumerStatefulWidget {
  const EvenementsPage({super.key});

  @override
  ConsumerState<EvenementsPage> createState() => _EvenementsPageState();
}

class _EvenementsPageState extends ConsumerState<EvenementsPage> {
  String _searchQuery = '';
  String? _selectedType;

  final List<String> _typesEvenement = const [
    'Camp',
    'Sortie',
    'Réunion',
    'Formation',
    'Week-end',
    'Autre',
  ];

  // 🎨 Couleurs associées aux unités
  final Map<int, Color> _unitColors = const {
    0: Color(0xFF65BC99), // Farfadets
    1: Color(0xFFFF8300), // Louveteaux
    2: Color(0xFF0077b3), // Éclaireurs
    3: Color(0xFFd03f15), // Pionniers
    4: Color(0xFF007254), // Routiers
    5: Color(0xFF6e74aa), // Maitrise
    6: Color(0xFF455A64), // Groupe complet
  };

  @override
  Widget build(BuildContext context) {
    final asyncEvents = ref.watch(evenementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: () => ref.read(evenementsProvider.notifier).reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Barre de recherche + filtre
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un événement...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  hint: const Text('Type'),
                  value: _selectedType,
                  onChanged: (value) => setState(() => _selectedType = value),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous')),
                    ..._typesEvenement.map(
                          (t) => DropdownMenuItem(value: t, child: Text(t)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📋 Liste des événements
          Expanded(
            child: asyncEvents.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (events) {
                final filtered = events.where((evt) {
                  final matchesName = evt.nom.toLowerCase().contains(_searchQuery);
                  final matchesType = _selectedType == null || evt.type == _selectedType;
                  return matchesName && matchesType;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Aucun événement trouvé.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final evt = filtered[index];

                    // 🟩 Déterminer la couleur selon la première unité
                    final mainUnitId = evt.unites.isNotEmpty ? evt.unites.first : null;
                    final cardColor = mainUnitId != null
                        ? _unitColors[mainUnitId] ?? Colors.grey.shade300
                        : Colors.grey.shade200;

                    final unitLabel = mainUnitId != null
                        ? _unitName(mainUnitId)
                        : 'Aucune unité';

                    return Card(
                      color: cardColor,
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: cardColor,
                          child: const Icon(Icons.event, color: Colors.white),
                        ),
                        title: Text(
                          evt.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📅 Du ${_formatDate(evt.date)} au ${_formatDate(evt.dateFin)}'),
                              Text('🗂️ Type : ${evt.type}'),
                              Text('🏕️ Unité : $unitLabel'),
                              Text(
                                '⛺ Tentes : ${evt.tentesAssociees.isEmpty ? "Aucune" : evt.tentesAssociees.join(", ")}',
                              ),
                            ],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            final ctrl = ref.read(evenementsProvider.notifier);
                            if (value == 'edit') {
                              await _showEventDialog(context, ctrl, event: evt);
                            } else if (value == 'delete') {
                              await ctrl.deleteEvenement(evt.id);
                            } else if (value == 'menus') {
                              _openEventDetail(context, evt, openMenus: true); // ✅
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Modifier')),
                            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                            PopupMenuDivider(),
                            PopupMenuItem(value: 'menus', child: Text('Ouvrir Menus')),
                          ],
                        ),
                        onTap: () => _openEventDetail(context, evt), // ✅ tap simple → détail normal
                      ),

                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _showEventDialog(context, ref.read(evenementsProvider.notifier));
        },
        label: const Text('Nouvel événement'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // 🧭 Formattage date
  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  // 🔤 Nom lisible pour une unité
  String _unitName(int id) {
    switch (id) {
      case  0:
        return 'Farfadets';
      case 1:
        return 'Louveteaux/Jeannettes';
      case 2:
        return 'Scouts/Guides';
      case 3:
        return 'Pionniers/Caravelles';
      case 4:
        return 'Compagnons';
      case 5:
        return 'Maitrise';
      case 6:
        return 'Groupe complet';
      default:
        return 'Unité inconnue';
    }
  }

  void _openEventDetail(BuildContext context, Event evt, {bool openMenus = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvenementDetailPage(
          eventId: evt.id.toString(),
          openMenusDirectly: openMenus,
        ),
      ),
    );
  }


  Future<void> _showEventDialog(
      BuildContext context,
      EvenementController ctrl, {
        Event? event,
      }) async {
    final isEditing = event != null;
    final nomController = TextEditingController(text: event?.nom ?? '');
    final typeController = TextEditingController(text: event?.type ?? '');
    final typesEvenement = _typesEvenement;

    DateTime debut = event?.date ?? DateTime.now();
    DateTime fin = event?.dateFin ?? DateTime.now().add(const Duration(days: 1));

    // ✅ Unités disponibles
    final unitOptions = const {
      0: 'Farfadets',
      1: 'Louveteaux/Jeannettes',
      2: 'Scouts/Guides',
      3: 'Pionniers/Caravelles',
      4: 'Compagnons',
      5: 'Maitrise',
      6: 'Groupe complet',
    };

    int? selectedUniteId =
    event?.unites.isNotEmpty == true ? event!.unites.first : null;

    // ✅ IDs des tentes sélectionnées
    List<int> selectedTenteIds = List.from(event?.tentesAssociees ?? []);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final asyncTentes = ref.watch(tentesProvider);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                24,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: StatefulBuilder(
                builder: (context, setStateDialog) => SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Text(
                        isEditing
                            ? 'Modifier l\'événement'
                            : 'Nouvel événement',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // 🏷 Nom
                      TextField(
                        controller: nomController,
                        decoration: const InputDecoration(
                          labelText: "Nom de l'événement",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🧩 Type
                      DropdownButtonFormField<String>(
                        value: typesEvenement.contains(typeController.text)
                            ? typeController.text
                            : null,
                        items: typesEvenement
                            .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            typeController.text = value ?? '';
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Type d'événement",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🏕️ Unité
                      DropdownButtonFormField<int>(
                        value: selectedUniteId,
                        items: unitOptions.entries
                            .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() => selectedUniteId = value);
                        },
                        decoration: const InputDecoration(
                          labelText: "Unité concernée",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 📅 Dates
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.date_range),
                              label: Text('Début : ${_formatDate(debut)}'),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: debut,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setStateDialog(() => debut = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event_available),
                              label: Text('Fin : ${_formatDate(fin)}'),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: fin,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setStateDialog(() => fin = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 🎪 Sélection des tentes
                      Text('Tentes associées',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),

                      asyncTentes.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (e, _) => Text('Erreur : $e'),
                        data: (tentes) {
                          if (tentes.isEmpty) {
                            return const Text('Aucune tente disponible.');
                          }

                          // 🕒 Récupération des tentes déjà prises pour le créneau
                          final indispoFuture = ref.watch(evenementsProvider.future).then((events) {
                            final indispo = <int>{};
                            for (final evt in events) {
                              final chevauche = debut.isBefore(evt.dateFin) && fin.isAfter(evt.date);
                              if (chevauche) {
                                indispo.addAll(evt.tentesAssociees);
                              }
                            }
                            return indispo;
                          });

                          return FutureBuilder<Set<int>>(
                            future: indispoFuture,
                            builder: (context, snapshot) {
                              final indispoIds = snapshot.data ?? {};

                              final sortedTentes = [...tentes]
                                ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final t in sortedTentes)
                                    FilterChip(
                                      label: Text(
                                        t.nom,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: indispoIds.contains(t.id)
                                              ? Colors.grey
                                              : Colors.black,
                                        ),
                                      ),
                                      backgroundColor: indispoIds.contains(t.id)
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade100,
                                      disabledColor: Colors.grey.shade200,
                                      selectedColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.2),
                                      side: BorderSide(
                                        color: selectedTenteIds.contains(t.id)
                                            ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.6)
                                            : Colors.grey.shade400,
                                      ),
                                      selected: selectedTenteIds.contains(t.id),
                                      onSelected: indispoIds.contains(t.id)
                                          ? null // 🚫 Désactivé si la tente est prise
                                          : (selected) {
                                        setStateDialog(() {
                                          if (selected) {
                                            selectedTenteIds.add(t.id);
                                          } else {
                                            selectedTenteIds.remove(t.id);
                                          }
                                        });
                                      },
                                    ),
                                ],
                              );
                            },
                          );
                        },

                      ),

                      const SizedBox(height: 24),

                      // ✅ Boutons d'action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Icon(isEditing ? Icons.save : Icons.add),
                            label:
                            Text(isEditing ? 'Enregistrer' : 'Créer'),
                            onPressed: () async {
                              if (nomController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Nom obligatoire')),
                                );
                                return;
                              }
                              if (selectedUniteId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Veuillez choisir une unité')),
                                );
                                return;
                              }

                              final evt = Event(
                                id: event?.id ?? 0,
                                nom: nomController.text,
                                type: typeController.text,
                                date: debut,
                                dateFin: fin,
                                tentesAssociees: selectedTenteIds,
                                unites: [selectedUniteId!],
                                groupeId: await LocalStorageService.instance.getGroupId(),
                              );

                              if (isEditing) {
                                await ctrl.updateEvenement(evt);
                              } else {
                                await ctrl.addEvenement(evt);
                              }

                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


}
