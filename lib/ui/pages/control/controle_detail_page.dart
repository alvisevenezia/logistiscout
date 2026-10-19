import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/ui/controllers/controle_controller.dart';
import 'package:logistiscout/ui/pages/control/controle_edit_page.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/ui/widgets/common/hearder_card.dart';

class ControleDetailPage extends ConsumerWidget {
  final Control controle;
  final Tent tente;

  const ControleDetailPage({
    super.key,
    required this.controle,
    required this.tente,
  });

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _edit(BuildContext context) async {
    var controllerName = controle.checklist['nom_controleur']?.toString() ?? '';
    if (controllerName.trim().isEmpty) {
      controllerName =
          await LocalStorageService.instance.getControllerName() ?? '';
    }
    if (!context.mounted) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ControlEditPage(
          tent: tente,
          controllerName: controllerName,
          initialControl: controle,
        ),
      ),
    );
    // Retour à la liste, qui est rechargée avec le contrôle modifié.
    if (saved == true && context.mounted) Navigator.pop(context, true);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce contrôle ?'),
        content: Text(
          'Contrôle du ${_formatDate(controle.date)} : la suppression est définitive (photos comprises).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(controlProvider(controle.tentId).notifier)
          .deleteControl(controle.id!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contrôle supprimé.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du contrôle'),
        actions: [
          if (controle.id != null) ...[
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context),
            ),
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: HeaderCard(tent: tente),
          ),
          Expanded(
            child: ListView(
              children: [
                // 📋 Info contrôle
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations du contrôle',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          label: 'Date',
                          value: _formatDate(controle.date),
                        ),
                        if (controle.checklist.containsKey(
                          "nom_controleur",
                        )) ...[
                          _InfoRow(
                            label: 'Contrôleur',
                            value: controle.checklist['nom_controleur'],
                          ),
                        ],
                        if (controle.checklist.containsKey(
                          "Nombre de sardines/piquets",
                        )) ...[
                          _InfoRow(
                            label: 'Nombre de sardines',
                            value:
                                ((controle.checklist["Nombre de sardines/piquets"] ==
                                                null ||
                                            controle
                                                .checklist["Nombre de sardines/piquets"]
                                                .toString()
                                                .isEmpty)
                                        ? 0
                                        : controle
                                              .checklist["Nombre de sardines/piquets"])
                                    .toString(),
                          ),
                        ],

                        if (controle.comment.isNotEmpty) ...[
                          Text(
                            'Remarques ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(controle.comment),
                        ],
                        if (controle.imageUrls.isNotEmpty ||
                            (controle.imageUrl != null &&
                                controle.imageUrl!.isNotEmpty)) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Photos',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final photoUrl
                                  in controle.imageUrls.isNotEmpty
                                      ? controle.imageUrls
                                      : [controle.imageUrl!])
                                SizedBox(
                                  width: 110,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _openPhotoViewer(
                                        context,
                                        controle.imageUrls.isNotEmpty
                                            ? controle.imageUrls
                                            : [controle.imageUrl!],
                                        photoUrl,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Image.network(
                                            photoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, error, stackTrace) {
                                              developer.log(
                                                'Thumbnail image load failed for $photoUrl: $error',
                                                name: 'ControleDetailPage',
                                                error: error,
                                                stackTrace: stackTrace,
                                              );
                                              return Container(
                                                color: Colors.black12,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Checklist
                if (controle.checklist.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Checklist du contrôle',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 20),
                          ...controle.checklist.entries
                              .where((entry) => entry.value is bool)
                              .map((entry) {
                                final value = entry.value;
                                Widget icon = Icon(
                                  value ? Icons.check_circle : Icons.cancel,
                                  color: value
                                      ? Colors.green
                                      : Colors.redAccent,
                                );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      icon,
                                    ],
                                  ),
                                );
                              }),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openPhotoViewer(
  BuildContext context,
  List<String> photoUrls,
  String initialPhotoUrl,
) async {
  final initialIndex = photoUrls.indexOf(initialPhotoUrl);
  final controller = PageController(
    initialPage: initialIndex >= 0 ? initialIndex : 0,
  );

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: SizedBox.expand(
          child: Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: photoUrls.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        photoUrls[index],
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stackTrace) {
                          developer.log(
                            'Fullscreen image load failed for ${photoUrls[index]}: $error',
                            name: 'ControleDetailPage',
                            error: error,
                            stackTrace: stackTrace,
                          );
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white70,
                              size: 56,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
