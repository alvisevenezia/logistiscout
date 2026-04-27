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

          final theme = Theme.of(context);
          final inputDecoration = InputDecoration(
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
          );

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.outlineVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing
                                          ? 'Modifier l\'événement'
                                          : 'Nouvel événement',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Renseigne les infos puis sélectionne les tentes disponibles.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Fermer',
                                onPressed: () => Navigator.pop(sheetContext),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _EventFormSection(
                            title: 'Informations',
                            icon: Icons.edit_calendar,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: nomController,
                                  decoration: inputDecoration.copyWith(
                                    labelText: "Nom de l'événement",
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
                                      typesEvenement.contains(
                                        typeController.text,
                                      )
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
                                  decoration: inputDecoration.copyWith(
                                    labelText: "Type d'événement",
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
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
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
                                    setStateDialog(
                                      () => selectedUniteId = value,
                                    );
                                  },
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Unité concernée',
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _EventFormSection(
                            title: 'Période',
                            icon: Icons.date_range,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.event),
                                        label: Text(
                                          'Début : ${_formatDate(debut)}',
                                        ),
                                        onPressed: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: debut,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            setStateDialog(
                                              () => debut = picked,
                                            );
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
                                        label: Text(
                                          'Fin : ${_formatDate(fin)}',
                                        ),
                                        onPressed: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: fin.isAfter(debut)
                                                ? fin
                                                : debut,
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
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Les tentes indisponibles sur cette période seront grisées.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _EventFormSection(
                            title: 'Tentes associées',
                            icon: Icons.cabin,
                            child: asyncTentList.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                                        if (isEditing && evt.id == event.id) {
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
                                    final availableTentes = sortedTentes
                                        .where(
                                          (t) => !indispoIds.contains(t.id),
                                        )
                                        .toList();
                                    final unavailableTentes = sortedTentes
                                        .where((t) => indispoIds.contains(t.id))
                                        .toList();

                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final t in availableTentes)
                                          FilterChip(
                                            label: Text(
                                              t.nom,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            backgroundColor: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            selectedColor: theme
                                                .colorScheme
                                                .primary
                                                .withAlpha(45),
                                            side: BorderSide(
                                              color:
                                                  selectedTenteIds.contains(
                                                    t.id,
                                                  )
                                                  ? theme.colorScheme.primary
                                                        .withAlpha(150)
                                                  : theme
                                                        .colorScheme
                                                        .outlineVariant,
                                            ),
                                            selected: selectedTenteIds.contains(
                                              t.id,
                                            ),
                                            onSelected: (selected) {
                                              setStateDialog(() {
                                                if (selected) {
                                                  selectedTenteIds.add(t.id);
                                                } else {
                                                  selectedTenteIds.remove(t.id);
                                                }
                                              });
                                            },
                                          ),
                                        if (unavailableTentes.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: double.infinity,
                                            child: Text(
                                              'Indisponibles sur la période',
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                          for (final t in unavailableTentes)
                                            FilterChip(
                                              label: Text(
                                                t.nom,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              backgroundColor: theme
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              disabledColor: theme
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              selectedColor: theme
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              side: BorderSide(
                                                color: theme
                                                    .colorScheme
                                                    .outlineVariant,
                                              ),
                                              selected: false,
                                              onSelected: null,
                                            ),
                                        ],
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.pop(sheetContext),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Annuler'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    isEditing ? Icons.save : Icons.add,
                                  ),
                                  label: Text(
                                    isEditing ? 'Enregistrer' : 'Créer',
                                  ),
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    final savedEvent = Event(
                                      id: isEditing ? event.id : -1,
                                      nom: nomController.text.trim(),
                                      type: typeController.text.trim(),
                                      date: debut,
                                      dateFin: fin,
                                      associatedTents: selectedTenteIds,
                                      unites: [selectedUniteId!],
                                      groupId: '0',
                                    );

                                    if (isEditing) {
                                      await controller.updateEvenement(
                                        savedEvent,
                                      );
                                    } else {
                                      await controller.addEvenement(savedEvent);
                                    }

                                    if (onSaved != null) {
                                      await onSaved(savedEvent);
                                    }

                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

class _EventFormSection extends StatelessWidget {
  const _EventFormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
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

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
