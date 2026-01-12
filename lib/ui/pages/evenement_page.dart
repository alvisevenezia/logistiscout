import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/unit.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/ui/controllers/evenement_controller.dart';
import 'package:logistiscout/ui/pages/evenement_detail/evenement_detail_page.dart';
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

  @override
  Widget build(BuildContext context) {
    final asyncEvents = ref.watch(evenementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),

      ),
      body: Column(
        children: [
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
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(tentesProvider.notifier).reload();
                await ref.read(evenementsProvider.notifier).reload();
              },
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
              
                      final mainUnit = evt.unites.isNotEmpty ? evt.unites.first : null;
                      final cardColor = mainUnit != null
                          ? Color(mainUnit.color)
                          : Colors.grey.shade200;
              
                      final unitLabel = mainUnit != null
                          ? mainUnit.name
                          : 'Aucune unité';

                      final textColor = ThemeData.estimateBrightnessForColor(cardColor) == Brightness.dark
                          ? Colors.white
                          : Colors.black;
              
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
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📅 Du ${_formatDate(evt.date)} au ${_formatDate(evt.dateFin)}',
                                    style: TextStyle(
                                      color: textColor)
                                ),
                                Text('🗂️ Type : ${evt.type}',
                                    style: TextStyle(
                                        color: textColor)
                                ),
                                Text('🏕️ Unité : $unitLabel',
                                    style: TextStyle(
                                        color: textColor)
                                ),
                                Text(
                                  '⛺ Tentes : ${evt.associatedTents.isEmpty ? "Aucune" : evt.associatedTents.join(", ")}',
                                    style: TextStyle(
                                        color: textColor)
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
                                _openEventDetail(context, evt, openMenus: true);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Modifier')),
                              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                              PopupMenuDivider(),
                              PopupMenuItem(value: 'menus', child: Text('Ouvrir Menus')),
                            ],
                          ),
                          onTap: () => _openEventDetail(context, evt),
                        ),
              
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajouter un évènement',
        onPressed: () async {
          await _showEventDialog(context, ref.read(evenementsProvider.notifier));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _openEventDetail(BuildContext context, Event evt, {bool openMenus = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvenementDetailPage(
          eventId: evt.id,
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

    Unit? selectedUnite = event?.unites.isNotEmpty == true ? event!.unites.first : null;

    List<int> selectedTenteIds = List.from(event?.associatedTents ?? []);

    final formKey = GlobalKey<FormState>();

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
            final asyncTentList = ref.watch(tentesProvider);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                24,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: StatefulBuilder(
                builder: (context, setStateDialog) => SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // petit handle
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

                        // titre
                        Text(
                          isEditing ? 'Modifier l\'événement' : 'Nouvel événement',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),

                        // 🏷 Nom
                        TextFormField(
                          controller: nomController,
                          decoration: const InputDecoration(
                            labelText: "Nom de l'événement",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nom obligatoire';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // 🧩 Type
                        DropdownButtonFormField<String>(
                          initialValue: typesEvenement.contains(typeController.text)
                              ? typeController.text
                              : null,
                          items: typesEvenement
                              .map(
                                (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ),
                          )
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
                        DropdownButtonFormField<Unit>(
                          initialValue: selectedUnite,
                          items: Unit.values
                              .map(
                                (e) => DropdownMenuItem(
                              value: e,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Color(e.color),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(e.name),
                                ],
                              ),
                            ),
                          )
                              .toList(),
                          onChanged: (value) {
                            setStateDialog(() => selectedUnite = value);
                          },
                          decoration: const InputDecoration(
                            labelText: "Unité concernée",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez choisir une unité';
                            }
                            return null;
                          },
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
                                    if (fin.isBefore(debut)) {
                                      setStateDialog(
                                            () => fin = debut.add(const Duration(days: 1)),
                                      );
                                    }
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
                                    initialDate: fin.isAfter(debut) ? fin : debut,
                                    firstDate: debut,
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
                        Text(
                          'Tentes associées',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),

                        asyncTentList.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (e, _) => Text('Erreur : $e'),
                          data: (tentes) {
                            if (tentes.isEmpty) {
                              return const Text('Aucune tente disponible.');
                            }

                            final indispoFuture = ref
                                .watch(evenementsProvider.future)
                                .then((events) {
                              final indispo = <int>{};
                              for (final evt in events) {
                                final chevauche = debut.isBefore(evt.dateFin) &&
                                    fin.isAfter(evt.date);
                                if (chevauche) {
                                  indispo.addAll(evt.associatedTents);
                                }
                              }
                              return indispo;
                            });

                            return FutureBuilder<Set<int>>(
                              future: indispoFuture,
                              builder: (context, snapshot) {
                                final indispoIds = snapshot.data ?? {};

                                final sortedTentes = [...tentes]
                                  ..sort(
                                        (a, b) => a.nom
                                        .toLowerCase()
                                        .compareTo(b.nom.toLowerCase()),
                                  );

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
                                        selectedColor:
                                        Theme.of(context).colorScheme.primary
                                            .withAlpha(45),
                                        side: BorderSide(
                                          color: selectedTenteIds.contains(t.id)
                                              ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withAlpha(150)
                                              : Colors.grey.shade400,
                                        ),
                                        selected:
                                        selectedTenteIds.contains(t.id),
                                        onSelected: indispoIds.contains(t.id)
                                            ? null
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
                              label: Text(isEditing ? 'Enregistrer' : 'Créer'),
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                final groupId =
                                await LocalStorageService.instance
                                    .getGroupId();

                                if (groupId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Impossible de récupérer le groupe.'),
                                    ),
                                  );
                                  return;
                                }

                                final newEvent = Event(
                                  id: isEditing ? event.id : -1,
                                  nom: nomController.text.trim(),
                                  type: typeController.text.trim(),
                                  date: debut,
                                  dateFin: fin,
                                  associatedTents: selectedTenteIds,
                                  unites: [selectedUnite!],
                                  groupId: groupId,
                                );

                                if (isEditing) {
                                  await ctrl.updateEvenement(newEvent);
                                } else {
                                  await ctrl.addEvenement(newEvent);
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
              ),
            );
          },
        );
      },
    );
  }



}
