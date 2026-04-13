import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/ui/controllers/evenement_controller.dart';
import 'package:logistiscout/ui/controllers/tentes_controller.dart';

Future<void> showEventFormSheet({
  required BuildContext context,
  required WidgetRef ref,
  required EvenementController controller,
  Event? event,
  Future<void> Function(Event savedEvent)? onSaved,
}) async {
  final isEditing = event != null;

  final nomController = TextEditingController(text: event?.nom ?? '');
  final typeController = TextEditingController(text: event?.type ?? '');
  const typesEvenement = [
    'Camp',
    'Sortie',
    'Réunion',
    'Formation',
    'Week-end',
    'Autre',
  ];

  DateTime debut = event?.date ?? DateTime.now();
  DateTime fin = event?.dateFin ?? DateTime.now().add(const Duration(days: 1));

  int? selectedUniteId = event?.unites.isNotEmpty == true
      ? event!.unites.first
      : null;
  List<int> selectedTenteIds = List.from(event?.associatedTents ?? []);

  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Consumer(
        builder: (context, ref, _) {
          final asyncTentList = ref.watch(tentesProvider);
          final accountAsync = ref.watch(accountControllerProvider);
          final groupUnits =
              accountAsync.valueOrNull?.units ?? const <GroupUnit>[];

          if (selectedUniteId != null &&
              groupUnits.every((u) => int.tryParse(u.id) != selectedUniteId)) {
            selectedUniteId = null;
          }

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
                      DropdownButtonFormField<String>(
                        initialValue:
                            typesEvenement.contains(typeController.text)
                            ? typeController.text
                            : null,
                        items: typesEvenement
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
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
                      DropdownButtonFormField<int>(
                        initialValue: selectedUniteId,
                        items: groupUnits
                            .map(
                              (e) => DropdownMenuItem(
                                value: int.tryParse(e.id),
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
                            .where((item) => item.value != null)
                            .cast<DropdownMenuItem<int>>()
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() => selectedUniteId = value);
                        },
                        decoration: const InputDecoration(
                          labelText: "Unité concernée",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (groupUnits.isEmpty) {
                            return 'Ajoute d\'abord des unités dans les paramètres du groupe';
                          }
                          if (value == null) {
                            return 'Veuillez choisir une unité';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
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
                                      () => fin = debut.add(
                                        const Duration(days: 1),
                                      ),
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
                                  if (isEditing && evt.id == event!.id) {
                                    continue;
                                  }
                                  final chevauche =
                                      debut.isBefore(evt.dateFin) &&
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
                                  (a, b) => a.nom.toLowerCase().compareTo(
                                    b.nom.toLowerCase(),
                                  ),
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
                                      selectedColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withAlpha(45),
                                      side: BorderSide(
                                        color: selectedTenteIds.contains(t.id)
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withAlpha(150)
                                            : Colors.grey.shade400,
                                      ),
                                      selected: selectedTenteIds.contains(t.id),
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

                              final savedEvent = Event(
                                id: isEditing ? event!.id : -1,
                                nom: nomController.text.trim(),
                                type: typeController.text.trim(),
                                date: debut,
                                dateFin: fin,
                                associatedTents: selectedTenteIds,
                                unites: [selectedUniteId!],
                                groupId: '0',
                              );

                              if (isEditing) {
                                await controller.updateEvenement(savedEvent);
                              } else {
                                await controller.addEvenement(savedEvent);
                              }

                              if (onSaved != null) {
                                await onSaved(savedEvent);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
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

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
