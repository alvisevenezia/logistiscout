import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/group.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/unit.dart';
import 'package:logistiscout/ui/controllers/group_settings_controller.dart';

class GroupSettingsPage extends ConsumerStatefulWidget {
  const GroupSettingsPage({super.key});

  @override
  ConsumerState<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends ConsumerState<GroupSettingsPage> {
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _loginCtl = TextEditingController();

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _loginCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(accountControllerProvider);
    final controller = ref.read(accountControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametres du groupe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (group) {
          _syncProfileControllers(group);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfileCard(context, controller),
              const SizedBox(height: 16),
              _buildGroupTypeCard(group, controller),
              const SizedBox(height: 16),
              _buildReferencesCard(context, group, controller),
            ],
          );
        },
      ),
    );
  }

  void _syncProfileControllers(Group group) {
    if (_nameCtl.text != group.name) {
      _nameCtl.text = group.name;
    }
    if (_emailCtl.text != group.email) {
      _emailCtl.text = group.email;
    }
    if (_loginCtl.text != group.login) {
      _loginCtl.text = group.login;
    }
  }

  Widget _buildProfileCard(
    BuildContext context,
    GroupSettingsController controller,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations generales',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtl,
              decoration: const InputDecoration(
                labelText: 'Nom du groupe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailCtl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _loginCtl,
              decoration: const InputDecoration(
                labelText: 'Login',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                    onPressed: () async {
                      final ok = await controller.saveProfileFields(
                        name: _nameCtl.text,
                        email: _emailCtl.text,
                        login: _loginCtl.text,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Parametres enregistres'
                                : 'Impossible d enregistrer',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Mot de passe'),
                  onPressed: () async {
                    final newPwd = await _askPassword(context);
                    if (newPwd == null || newPwd.trim().isEmpty) return;
                    controller.setPassword(newPwd.trim());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTypeCard(Group group, GroupSettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type de groupe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            RadioListTile<String>(
              title: const Text('Scout'),
              value: 'scout',
              groupValue: group.type,
              onChanged: (v) {
                if (v != null) controller.setType(v);
              },
            ),
            RadioListTile<String>(
              title: const Text('Marin'),
              value: 'marin',
              groupValue: group.type,
              onChanged: (v) {
                if (v != null) controller.setType(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferencesCard(
    BuildContext context,
    Group group,
    GroupSettingsController controller,
  ) {
    return SizedBox(
      height: 560,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Referentiels du groupe',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const TabBar(
                tabs: [
                  Tab(text: 'Unites'),
                  Tab(text: 'Statuts tentes'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _UnitsTab(
                      units: group.units,
                      onAdd: () => _openUnitSheet(context, controller),
                      onEdit: (unit) => _openUnitSheet(
                        context,
                        controller,
                        initialUnit: unit,
                      ),
                      onDelete: (unit) async {
                        await controller.removeUnit(unit.id);
                      },
                    ),
                    _TentStatusesTab(
                      statuses: group.tentStatuses,
                      onAdd: () => _openStatusSheet(context, controller),
                      onEdit: (statusRef) => _openStatusSheet(
                        context,
                        controller,
                        initialStatus: statusRef,
                      ),
                      onDuplicate: (statusRef) async {
                        await controller.duplicateTentStatus(statusRef.id);
                      },
                      onArchive: (statusRef) async {
                        await controller.archiveTentStatus(statusRef.id);
                      },
                      onDelete: (statusRef) async {
                        await _deleteStatusWithReplacement(
                          context,
                          controller,
                          group,
                          statusRef,
                        );
                      },
                      onReorder: (ordered) async {
                        await controller.reorderTentStatuses(ordered);
                      },
                      onResetDefaults: () async {
                        await controller.restoreDefaultTentStatuses();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _askPassword(BuildContext context) async {
    final ctl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouveau mot de passe'),
        content: TextField(
          obscureText: true,
          controller: ctl,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctl.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    ctl.dispose();
    return value;
  }

  Future<void> _openUnitSheet(
    BuildContext context,
    GroupSettingsController controller, {
    GroupUnit? initialUnit,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UnitEditorSheet(
        initialUnit: initialUnit,
        onSubmit: (name, type, color) async {
          if (initialUnit == null) {
            await controller.addUnit(name: name, type: type, color: color);
          } else {
            await controller.updateUnit(
              initialUnit.id,
              name: name,
              color: color,
              type: type,
            );
          }
        },
      ),
    );
  }

  Future<void> _openStatusSheet(
    BuildContext context,
    GroupSettingsController controller, {
    TentStatusRef? initialStatus,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StatusEditorSheet(
        initialStatus: initialStatus,
        onSubmit: (name, color) async {
          if (initialStatus == null) {
            await controller.addTentStatus(name: name, color: color);
          } else {
            await controller.updateTentStatus(
              initialStatus.id,
              name: name,
              color: color,
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteStatusWithReplacement(
    BuildContext context,
    GroupSettingsController controller,
    Group group,
    TentStatusRef target,
  ) async {
    final alternatives = group.tentStatuses
        .where((s) => s.id != target.id && !s.isArchived)
        .toList();
    int? replacementId = alternatives.isNotEmpty ? alternatives.first.id : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer ${target.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Si ce statut est utilise, les tentes seront migrees vers le statut de remplacement.',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: replacementId,
              items: alternatives
                  .map(
                    (s) =>
                        DropdownMenuItem<int>(value: s.id, child: Text(s.name)),
                  )
                  .toList(),
              onChanged: (v) => replacementId = v,
              decoration: const InputDecoration(
                labelText: 'Remplacer par',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await controller.removeTentStatus(
        target.id,
        replacementStatusId: replacementId,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Suppression impossible: $e')));
    }
  }
}

class _UnitsTab extends StatefulWidget {
  const _UnitsTab({
    required this.units,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<GroupUnit> units;
  final VoidCallback onAdd;
  final ValueChanged<GroupUnit> onEdit;
  final ValueChanged<GroupUnit> onDelete;

  @override
  State<_UnitsTab> createState() => _UnitsTabState();
}

class _UnitsTabState extends State<_UnitsTab> {
  late List<GroupUnit> _local;

  @override
  void initState() {
    super.initState();
    _local = List<GroupUnit>.from(widget.units);
  }

  @override
  void didUpdateWidget(covariant _UnitsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _local = List<GroupUnit>.from(widget.units);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          itemCount: _local.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _local.removeAt(oldIndex);
            _local.insert(newIndex, item);
            setState(() {});
          },
          itemBuilder: (_, index) {
            final unit = _local[index];
            return Card(
              key: ValueKey('unit-${unit.id}'),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Color(unit.color)),
                title: Text(unit.name),
                subtitle: Text('Type: ${unit.type.name}'),
                onTap: () => widget.onEdit(unit),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => widget.onDelete(unit),
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'add-unit',
            onPressed: widget.onAdd,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _TentStatusesTab extends StatefulWidget {
  const _TentStatusesTab({
    required this.statuses,
    required this.onAdd,
    required this.onEdit,
    required this.onDuplicate,
    required this.onArchive,
    required this.onDelete,
    required this.onReorder,
    required this.onResetDefaults,
  });

  final List<TentStatusRef> statuses;
  final VoidCallback onAdd;
  final ValueChanged<TentStatusRef> onEdit;
  final ValueChanged<TentStatusRef> onDuplicate;
  final ValueChanged<TentStatusRef> onArchive;
  final ValueChanged<TentStatusRef> onDelete;
  final Future<void> Function(List<TentStatusRef>) onReorder;
  final Future<void> Function() onResetDefaults;

  @override
  State<_TentStatusesTab> createState() => _TentStatusesTabState();
}

class _TentStatusesTabState extends State<_TentStatusesTab> {
  late List<TentStatusRef> _local;

  @override
  void initState() {
    super.initState();
    _local = _sorted(widget.statuses);
  }

  @override
  void didUpdateWidget(covariant _TentStatusesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _local = _sorted(widget.statuses);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await widget.onResetDefaults();
                },
                icon: const Icon(Icons.restore),
                label: const Text('Restaurer les valeurs par defaut'),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                itemCount: _local.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _local.removeAt(oldIndex);
                  _local.insert(newIndex, item);
                  setState(() {});
                  await widget.onReorder(_local);
                },
                itemBuilder: (_, index) {
                  final item = _local[index];
                  return Card(
                    key: ValueKey('status-${item.id}'),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Color(item.color)),
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.isArchived ? 'Archive' : 'Actif'}${item.isDefault ? ' • Defaut' : ''}',
                      ),
                      onTap: () => widget.onEdit(item),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Dupliquer',
                            onPressed: () => widget.onDuplicate(item),
                            icon: const Icon(Icons.copy_outlined),
                          ),
                          IconButton(
                            tooltip: 'Archiver',
                            onPressed: () => widget.onArchive(item),
                            icon: const Icon(Icons.archive_outlined),
                          ),
                          IconButton(
                            tooltip: 'Supprimer',
                            onPressed: () => widget.onDelete(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'add-status',
            onPressed: widget.onAdd,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  List<TentStatusRef> _sorted(List<TentStatusRef> input) {
    final out = List<TentStatusRef>.from(input);
    out.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      return a.id.compareTo(b.id);
    });
    return out;
  }
}

class _UnitEditorSheet extends StatefulWidget {
  const _UnitEditorSheet({required this.onSubmit, this.initialUnit});

  final GroupUnit? initialUnit;
  final Future<void> Function(String name, Unit type, int color) onSubmit;

  @override
  State<_UnitEditorSheet> createState() => _UnitEditorSheetState();
}

class _UnitEditorSheetState extends State<_UnitEditorSheet> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _hexCtl;
  late Unit _type;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.initialUnit?.name ?? '');
    _type = widget.initialUnit?.type ?? Unit.aucun;
    _color = Color(widget.initialUnit?.color ?? Unit.aucun.color);
    _hexCtl = TextEditingController(text: _hex(_color));
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _hexCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.initialUnit == null ? 'Ajouter une unite' : 'Modifier unite',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtl,
            decoration: const InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Unit>(
            initialValue: _type,
            items: Unit.values
                .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _type = v);
            },
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _hexCtl,
            decoration: const InputDecoration(
              labelText: 'Couleur hex',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              final parsed = _parseHex(v);
              if (parsed != null) {
                setState(() => _color = parsed);
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(backgroundColor: _color),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  await _pickColor(context);
                  _hexCtl.text = _hex(_color);
                },
                child: const Text('Choisir'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await widget.onSubmit(
                  _nameCtl.text.trim(),
                  _type,
                  _color.toARGB32(),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Valider'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    Color temp = _color;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Couleur'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _color,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _color = temp);
              Navigator.pop(context);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Color? _parseHex(String value) {
    final cleaned = value
        .trim()
        .replaceAll('#', '')
        .replaceFirst(RegExp(r'^0x', caseSensitive: false), '');
    final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    if (normalized.length != 8) return null;
    try {
      return Color(int.parse(normalized, radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _StatusEditorSheet extends StatefulWidget {
  const _StatusEditorSheet({required this.onSubmit, this.initialStatus});

  final TentStatusRef? initialStatus;
  final Future<void> Function(String name, int color) onSubmit;

  @override
  State<_StatusEditorSheet> createState() => _StatusEditorSheetState();
}

class _StatusEditorSheetState extends State<_StatusEditorSheet> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _hexCtl;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.initialStatus?.name ?? '');
    _color = Color(widget.initialStatus?.color ?? 0xFF388E3C);
    _hexCtl = TextEditingController(text: _hex(_color));
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _hexCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.initialStatus == null
                ? 'Ajouter un statut'
                : 'Modifier statut',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtl,
            decoration: const InputDecoration(
              labelText: 'Nom du statut',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _hexCtl,
            decoration: const InputDecoration(
              labelText: 'Couleur hex',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              final parsed = _parseHex(v);
              if (parsed != null) {
                setState(() => _color = parsed);
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(backgroundColor: _color),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  await _pickColor(context);
                  _hexCtl.text = _hex(_color);
                },
                child: const Text('Choisir'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await widget.onSubmit(_nameCtl.text.trim(), _color.toARGB32());
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Valider'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    Color temp = _color;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Couleur'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _color,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _color = temp);
              Navigator.pop(context);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Color? _parseHex(String value) {
    final cleaned = value
        .trim()
        .replaceAll('#', '')
        .replaceFirst(RegExp(r'^0x', caseSensitive: false), '');
    final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    if (normalized.length != 8) return null;
    try {
      return Color(int.parse(normalized, radix: 16));
    } catch (_) {
      return null;
    }
  }
}
