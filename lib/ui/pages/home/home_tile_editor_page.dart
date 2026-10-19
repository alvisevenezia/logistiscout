import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/home_tile.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/ui/controllers/home_controller.dart';
import 'package:logistiscout/ui/widgets/home/home_stat_card.dart';

const _tentTypes = ['Canadienne', 'Tipi', 'Marabout', 'Autre'];

/// Création ou modification d'une vignette. Renvoie la vignette via
/// `Navigator.pop`.
///
/// Pour « Opérationnelles », seuls les statuts comptés sont modifiables.
class HomeTileEditorPage extends ConsumerStatefulWidget {
  const HomeTileEditorPage({super.key, this.initial});

  final HomeTile? initial;

  @override
  ConsumerState<HomeTileEditorPage> createState() => _HomeTileEditorPageState();
}

class _HomeTileEditorPageState extends ConsumerState<HomeTileEditorPage> {
  late final TextEditingController _titleCtl;
  late final TextEditingController _subtitleCtl;
  late HomeTile _tile;
  String? _titleError;

  bool get _isNew => widget.initial == null;
  bool get _isCustom => _tile.isCustom;

  @override
  void initState() {
    super.initState();
    _tile =
        widget.initial ??
        HomeTile(
          id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
          kind: HomeTileKind.custom,
          color: defaultCustomTileColor,
          icon: defaultCustomTileIcon,
        );
    _titleCtl = TextEditingController(text: _tile.title ?? '');
    _subtitleCtl = TextEditingController(text: _tile.subtitle ?? '');
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _subtitleCtl.dispose();
    super.dispose();
  }

  HomeTile get _edited => _isCustom
      ? _tile.copyWith(
          title: _titleCtl.text.trim(),
          subtitle: _subtitleCtl.text.trim(),
        )
      : _tile;

  void _submit() {
    if (_isCustom && _titleCtl.text.trim().isEmpty) {
      setState(() => _titleError = 'Donnez un nom à la vignette');
      return;
    }
    Navigator.of(context).pop(_edited);
  }

  void _toggleStatus(int id, bool selected) {
    final ids = [..._tile.statusIds];
    selected ? ids.add(id) : ids.remove(id);
    setState(() => _tile = _tile.copyWith(statusIds: ids));
  }

  void _toggleType(String type) {
    final types = [..._tile.tentTypes];
    types.contains(type) ? types.remove(type) : types.add(type);
    setState(() => _tile = _tile.copyWith(tentTypes: types));
  }

  @override
  Widget build(BuildContext context) {
    final statuses = [
      ...(ref.watch(accountControllerProvider).valueOrNull?.tentStatuses ??
              const <TentStatusRef>[])
          .where((s) => !s.isArchived),
    ]..sort((a, b) => a.order.compareTo(b.order));
    final tents = ref.watch(accueilControllerProvider).tentes;
    final card = homeStatCardFor(
      _edited,
      HomeOverviewData(
        tents: tents,
        statuses: statuses,
        upcomingEventsCount: 0,
        usedTentsCount: 0,
      ),
    );
    final theme = Theme.of(context);
    final plural = card.value != '1' && card.value != '0';

    Widget sectionLabel(String text, [String? hint]) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: theme.textTheme.titleSmall,
          children: [
            if (hint != null)
              TextSpan(text: ' $hint', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNew
              ? 'Nouvelle vignette'
              : _isCustom
              ? 'Modifier la vignette'
              : card.title,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              SizedBox(width: 190, child: HomeStatCard(data: card)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  plural
                      ? 'Aperçu en direct : ${card.value} tentes correspondent aujourd\'hui.'
                      : 'Aperçu en direct : ${card.value} tente correspond aujourd\'hui.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (_isCustom) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtl,
              maxLength: 40,
              decoration: InputDecoration(
                labelText: 'Nom',
                border: const OutlineInputBorder(),
                errorText: _titleError,
              ),
              onChanged: (_) => setState(() => _titleError = null),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subtitleCtl,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Sous-titre',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            sectionLabel('Couleur et icône'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final color in homeTilePalette.keys)
                  _ColorSwatch(
                    color: Color(color),
                    selected: _tile.color == color,
                    onTap: () =>
                        setState(() => _tile = _tile.copyWith(color: color)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in homeTileIcons.entries)
                  IconButton.outlined(
                    tooltip: 'Icône ${entry.key}',
                    isSelected: _tile.icon == entry.key,
                    onPressed: () => setState(
                      () => _tile = _tile.copyWith(icon: entry.key),
                    ),
                    icon: Icon(entry.value),
                  ),
              ],
            ),
          ],
          sectionLabel('Compter les tentes dont le statut est'),
          if (_tile.statusIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _isCustom
                    ? 'Aucun statut coché : tous les statuts.'
                    : 'Aucun statut coché : toutes les tentes non marquées « à réparer ».',
                style: theme.textTheme.bodySmall,
              ),
            ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final status in statuses)
                  CheckboxListTile(
                    value: _tile.statusIds.contains(status.id),
                    onChanged: (v) => _toggleStatus(status.id, v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Row(
                      children: [
                        // Contour : certaines couleurs de statut sont très
                        // pâles (« À réparer », « HS » par défaut).
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(status.color),
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(child: Text(status.name)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_isCustom) ...[
            sectionLabel('Type de matériel', '(facultatif)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tous'),
                  selected: _tile.tentTypes.isEmpty,
                  onSelected: (_) => setState(
                    () => _tile = _tile.copyWith(tentTypes: const []),
                  ),
                ),
                for (final type in _tentTypes)
                  FilterChip(
                    label: Text(type),
                    selected: _tile.tentTypes.contains(type),
                    onSelected: (_) => _toggleType(type),
                  ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _submit,
            child: Text(_isNew ? "Ajouter à l'accueil" : 'Enregistrer'),
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Couleur',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
