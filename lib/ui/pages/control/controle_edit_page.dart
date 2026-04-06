import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/status_element_control.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/ui/controllers/controle_controller.dart';
import 'package:logistiscout/ui/controllers/tentes_controller.dart';

class ControlEditPage extends ConsumerStatefulWidget {
  final Tent tent;
  final String controllerName;

  const ControlEditPage({
    super.key,
    required this.tent,
    required this.controllerName,
  });

  @override
  ConsumerState<ControlEditPage> createState() => _ControlEditPageState();
}

class _ControlEditPageState extends ConsumerState<ControlEditPage> {
  final TextEditingController remarquesController = TextEditingController();
  final TextEditingController sardinesController = TextEditingController();
  final Map<String, bool> checklist = {};
  final Map<String, StatusElementControl?> statusByItem = {};
  TentState? _state;
  final List<_PendingPhoto> _selectedPhotos = [];

  @override
  void dispose() {
    remarquesController.dispose();
    sardinesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final newPhotos = <_PendingPhoto>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) {
        continue;
      }
      newPhotos.add(_PendingPhoto(bytes: bytes, name: file.name));
    }

    if (newPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de lire les photos sélectionnées.'),
        ),
      );
      return;
    }

    setState(() {
      _selectedPhotos.addAll(newPhotos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();
    final explications = _explications();

    return Scaffold(
      appBar: AppBar(title: Text('Contrôle - ${widget.tent.nom}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            for (final section in sections.entries) ...[
              Text(
                section.key,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (explications[section.key] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    explications[section.key]!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 4),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      SizedBox(
                        width: 48,
                        child: Center(
                          child: Text(
                            "OK",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Center(
                          child: Text(
                            "KO",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...section.value.map((e) {
                    final status = statusByItem[e];

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e),

                        Row(
                          children: [
                            // OK checkbox
                            Checkbox(
                              activeColor: Colors.green,
                              value: status == StatusElementControl.ok,
                              onChanged: (checked) {
                                setState(() {
                                  statusByItem[e] = checked == true
                                      ? StatusElementControl.ok
                                      : null;
                                });
                              },
                            ),
                            // KO checkbox
                            Checkbox(
                              activeColor: Colors.red,
                              value: status == StatusElementControl.ko,
                              onChanged: (checked) {
                                setState(() {
                                  statusByItem[e] = checked == true
                                      ? StatusElementControl.ko
                                      : null;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: sardinesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          'Nbr de sardines (attendu : ${_expectedSardines(widget.tent.tentType)}) ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<TentState>(
                    initialValue: widget.tent.state,
                    items: TentState.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(tentStateToString(e)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _state = v ?? TentState.broken),
                    decoration: const InputDecoration(
                      labelText: 'État',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Photo du contrôle',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Ajouter une photo'),
                        ),
                      ],
                    ),
                    if (_selectedPhotos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (
                            var index = 0;
                            index < _selectedPhotos.length;
                            index++
                          )
                            SizedBox(
                              width: 110,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Image.memory(
                                        _selectedPhotos[index].bytes,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedPhotos[index].name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _selectedPhotos.removeAt(index);
                                    }),
                                    child: const Text('Retirer'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text('Aucune photo ajoutée.'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarquesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Remarques générales',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Valider le contrôle'),
              onPressed: () async {
                if (widget.controllerName.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez saisir le nom du contrôleur.'),
                    ),
                  );
                  return;
                }

                final payload = {
                  for (final e in statusByItem.entries) e.key: e.value,
                  'Nombre de sardines/piquets': sardinesController.text,
                  'nom_controleur': widget.controllerName.trim(),
                };

                final controle = Control(
                  id: null,
                  tentId: widget.tent.id,
                  date: DateTime.now(),
                  comment: remarquesController.text.trim(),
                  checklist: payload,
                  userId: 0,
                );

                final createdControl = await ref
                    .read(controlProvider(widget.tent.id).notifier)
                    .addControl(controle);

                if (_selectedPhotos.isNotEmpty && createdControl.id != null) {
                  for (final photo in _selectedPhotos) {
                    await ref
                        .read(controlProvider(widget.tent.id).notifier)
                        .uploadControlPicture(
                          controlId: createdControl.id!,
                          bytes: photo.bytes,
                          fileName: photo.name,
                        );
                  }
                }

                if (widget.tent.state != _state) {
                  ref
                      .read(tentesProvider.notifier)
                      .updateTente(widget.tent.copyWith(state: _state));
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contrôle enregistré avec succès !'),
                    ),
                  );
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<String>> _sections() => {
    'Structure et éléments principaux': [
      'Double-toit',
      'Toile intérieure',
      'Tapis de sol',
      'Faitières',
      'Piquets',
    ],
    'Fixations et fermetures': [
      'Fermetures éclair',
      'Œillets',
      'Tendeurs double-toit',
      'Tendeurs toile intérieure',
    ],
    'Accessoires et rangement': [
      'Sac de tente',
      'Sac de piquets',
      'Sac de sardines',
      'Maillet',
      'Ballayette',
    ],
    'État général': [
      'Propreté extérieure/intérieure',
      'Tente sèche',
      'Pas d’odeur de moisi',
    ],
  };

  Map<String, String> _explications() => {
    'Structure et éléments principaux':
        "Vérifier l'état de la toile, du sol, des mâts, haubans et sardines.",
    'Fixations et fermetures': "Contrôler les fermetures, œillets et attaches.",
    'Accessoires et rangement':
        "Présence et état de la housse et des accessoires.",
    'État général': "La tente doit être propre, sèche et sans odeur de moisi.",
  };

  String _expectedSardines(String typeTente) {
    switch (typeTente.toLowerCase()) {
      case 'canadienne':
        return '24';
      case 'tipi':
        return '27';
      default:
        return '-';
    }
  }
}

class _PendingPhoto {
  final Uint8List bytes;
  final String name;

  const _PendingPhoto({required this.bytes, required this.name});
}
