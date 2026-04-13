import 'dart:io';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
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
    developer.log('Opening photo picker', name: 'ControlEditPage');
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
      developer.log(
        'Picked file candidate: name=${file.name}, path=${file.path}, bytesInMemory=${file.bytes?.length ?? 0}',
        name: 'ControlEditPage',
      );
      var bytes = file.bytes;
      if (bytes == null && file.path != null) {
        try {
          bytes = await File(file.path!).readAsBytes();
          developer.log(
            'Loaded file bytes from path: ${file.path} (${bytes.length} bytes)',
            name: 'ControlEditPage',
          );
        } catch (_) {
          // Ignore unreadable files and continue with remaining selections.
          developer.log(
            'Failed to read file from path: ${file.path}',
            name: 'ControlEditPage',
          );
        }
      }
      if (bytes == null || bytes.isEmpty) {
        developer.log(
          'Skipping file because bytes are empty: ${file.name}',
          name: 'ControlEditPage',
        );
        continue;
      }
      final fileName = file.name.trim().isEmpty
          ? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : file.name;
      newPhotos.add(_PendingPhoto(bytes: bytes, name: fileName));
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
    developer.log(
      'Selected photos count is now ${_selectedPhotos.length}',
      name: 'ControlEditPage',
    );
  }

  Future<void> _takePhoto() async {
    developer.log('Opening camera for control photo', name: 'ControlEditPage');
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (picked == null) {
        developer.log(
          'Camera capture canceled by user',
          name: 'ControlEditPage',
        );
        return;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        developer.log('Captured photo is empty', name: 'ControlEditPage');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La photo capturée est vide.')),
          );
        }
        return;
      }

      final fileName = picked.name.trim().isEmpty
          ? 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : picked.name;

      setState(() {
        _selectedPhotos.add(_PendingPhoto(bytes: bytes, name: fileName));
      });

      developer.log(
        'Captured photo added: $fileName (${bytes.length} bytes). Selected count=${_selectedPhotos.length}',
        name: 'ControlEditPage',
      );
    } catch (e, st) {
      developer.log(
        'Camera capture failed: $e',
        name: 'ControlEditPage',
        error: e,
        stackTrace: st,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir la caméra: $e')),
        );
      }
    }
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
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Prendre une photo'),
                        ),
                        TextButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galerie'),
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
                developer.log(
                  'Save control tapped for tentId=${widget.tent.id}, selectedPhotos=${_selectedPhotos.length}',
                  name: 'ControlEditPage',
                );
                if (widget.controllerName.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez saisir le nom du contrôleur.'),
                    ),
                  );
                  return;
                }

                try {
                  final payload = {
                    for (final e in statusByItem.entries) e.key: e.value,
                    'Nombre de sardines/piquets': sardinesController.text,
                    'nom_controleur': widget.controllerName.trim(),
                  };

                  developer.log(
                    'Creating control with ${payload.length} checklist fields',
                    name: 'ControlEditPage',
                  );

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

                  var controlIdForUpload = createdControl.id;
                  if (controlIdForUpload == null &&
                      _selectedPhotos.isNotEmpty) {
                    developer.log(
                      'Created control returned null id, attempting fallback by reloading latest control list',
                      name: 'ControlEditPage',
                    );
                    final controls = await ref.read(
                      controlProvider(widget.tent.id).future,
                    );
                    if (controls.isNotEmpty) {
                      controlIdForUpload = controls.last.id;
                    }
                    developer.log(
                      'Fallback resolved control id to $controlIdForUpload',
                      name: 'ControlEditPage',
                    );
                  }

                  developer.log(
                    'Control created with id=${createdControl.id}, uploadId=$controlIdForUpload',
                    name: 'ControlEditPage',
                  );

                  if (_selectedPhotos.isNotEmpty &&
                      controlIdForUpload != null) {
                    for (var i = 0; i < _selectedPhotos.length; i++) {
                      final photo = _selectedPhotos[i];
                      developer.log(
                        'Uploading photo ${i + 1}/${_selectedPhotos.length}: name=${photo.name}, size=${photo.bytes.length} bytes, controlId=$controlIdForUpload',
                        name: 'ControlEditPage',
                      );
                      await ref
                          .read(controlProvider(widget.tent.id).notifier)
                          .uploadControlPicture(
                            controlId: controlIdForUpload,
                            bytes: photo.bytes,
                            fileName: photo.name,
                          );
                      developer.log(
                        'Photo ${i + 1}/${_selectedPhotos.length} uploaded successfully',
                        name: 'ControlEditPage',
                      );
                    }
                  } else {
                    developer.log(
                      'No photo upload performed (selectedPhotos=${_selectedPhotos.length}, controlId=$controlIdForUpload)',
                      name: 'ControlEditPage',
                    );
                  }

                  final selectedState = _state ?? widget.tent.state;

                  if (widget.tent.state != selectedState) {
                    developer.log(
                      'Updating tent state from ${widget.tent.state} to $selectedState',
                      name: 'ControlEditPage',
                    );
                    await ref
                        .read(tentesProvider.notifier)
                        .updateTente(
                          widget.tent.copyWith(
                            state: selectedState,
                            tentStatusId: null,
                            tentStatusLabel: tentStateToString(selectedState),
                            tentStatusColor: selectedState.chipColor,
                          ),
                        );
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contrôle enregistré avec succès !'),
                      ),
                    );
                    Navigator.pop(context, true);
                  }
                } catch (e, st) {
                  developer.log(
                    'Save control flow failed: $e',
                    name: 'ControlEditPage',
                    error: e,
                    stackTrace: st,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de l\'enregistrement: $e'),
                      ),
                    );
                  }
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
