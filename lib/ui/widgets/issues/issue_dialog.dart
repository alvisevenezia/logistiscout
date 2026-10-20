import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logistiscout/domain/entities/issue.dart';
import 'package:logistiscout/ui/controllers/controle_saisie_nom_controller.dart';
import 'package:logistiscout/ui/controllers/items_controller.dart';

/// Ouvre la fenêtre « Signaler un problème ». Renvoie true si un
/// signalement a été enregistré.
Future<bool> showIssueDialog(
  BuildContext context, {
  required IssueTarget target,
  required String targetName,
  int maxQuantity = 1,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => IssueDialog(
      target: target,
      targetName: targetName,
      maxQuantity: maxQuantity,
    ),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Signalement enregistré')));
  }
  return saved == true;
}

class IssueDialog extends ConsumerStatefulWidget {
  final IssueTarget target;
  final String targetName;
  final int maxQuantity;

  const IssueDialog({
    super.key,
    required this.target,
    required this.targetName,
    this.maxQuantity = 1,
  });

  @override
  ConsumerState<IssueDialog> createState() => _IssueDialogState();
}

class _IssueDialogState extends ConsumerState<IssueDialog> {
  static const _maxPhotoBytes = 8 * 1024 * 1024;

  late final TextEditingController _descriptionCtl;
  late final TextEditingController _quantityCtl;
  late final TextEditingController _reporterCtl;
  bool _usable = true;
  Uint8List? _photoBytes;
  String? _photoName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionCtl = TextEditingController();
    _quantityCtl = TextEditingController(text: '1');
    // Même nom que pour les contrôles : saisi une fois sur le téléphone.
    _reporterCtl = TextEditingController(
      text: ref.read(controleSaisieNomProvider),
    );
  }

  @override
  void dispose() {
    _descriptionCtl.dispose();
    _quantityCtl.dispose();
    _reporterCtl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    if (bytes.isEmpty || bytes.length > _maxPhotoBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo vide ou trop lourde.')),
      );
      return;
    }
    setState(() {
      _photoBytes = bytes;
      _photoName = picked.name.trim().isEmpty
          ? 'signalement_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : picked.name;
    });
  }

  Future<void> _submit() async {
    final description = _descriptionCtl.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Décrivez le problème')),
      );
      return;
    }
    final maxQuantity = widget.maxQuantity < 1 ? 1 : widget.maxQuantity;
    final quantity = (int.tryParse(_quantityCtl.text.trim()) ?? 1).clamp(
      1,
      maxQuantity,
    );
    final reporter = _reporterCtl.text.trim();
    if (reporter.isNotEmpty) {
      ref.read(controleSaisieNomProvider.notifier).updateNom(reporter);
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(issueActionsProvider)
          .report(
            target: widget.target,
            description: description,
            usable: _usable,
            quantity: quantity,
            reporterName: reporter.isEmpty ? null : reporter,
            photoBytes: _photoBytes,
            photoName: _photoName,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signalement impossible : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Signaler un problème'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.targetName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionCtl,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<bool>(
              initialValue: _usable,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: true,
                  child: Text('Utilisable (à réparer)'),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text('Inutilisable (hors service)'),
                ),
              ],
              onChanged: (v) => setState(() => _usable = v ?? true),
              decoration: const InputDecoration(labelText: 'Gravité'),
            ),
            if (widget.maxQuantity > 1) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _quantityCtl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantité concernée',
                  helperText: 'sur ${widget.maxQuantity}',
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _reporterCtl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Signalé par'),
            ),
            const SizedBox(height: 16),
            if (_photoBytes != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _photoBytes!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Retirer la photo',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _photoBytes = null;
                      _photoName = null;
                    }),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_camera),
                label: const Text('Ajouter une photo'),
                onPressed: _isSaving ? null : _pickPhoto,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_isSaving ? 'Envoi...' : 'Signaler'),
        ),
      ],
    );
  }
}
