import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'dart:developer' as developer;

import 'package:logistiscout/domain/entities/unit.dart';

class GroupSettingsPage extends ConsumerStatefulWidget {
  const GroupSettingsPage({super.key});

  @override
  ConsumerState<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends ConsumerState<GroupSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(accountControllerProvider);
    final controller = ref.read(accountControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres du groupe"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Erreur: $e")),
        data: (group) {
          developer.log("group loaded: ${group.name}");

          final nameController = TextEditingController(text: group.name);
          final emailController = TextEditingController(text: group.email);
          final loginController = TextEditingController(text: group.login);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ================= INFOS =================
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Informations générales",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Nom du groupe",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: controller.setName,
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: controller.setEmail,
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: loginController,
                        decoration: const InputDecoration(
                          labelText: "Login",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: controller.setLogin,
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: () async {
                          final newPwd = await askPassword(context);
                          if (newPwd != null) controller.setPassword(newPwd);
                        },
                        icon: const Icon(Icons.lock),
                        label: const Text("Changer le mot de passe"),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= TYPE =================
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Type de groupe",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      RadioListTile(
                        value: "scout",
                        groupValue: group.type,
                        onChanged: (v) => controller.setType(v!),
                        title: const Text("Scout"),
                      ),
                      RadioListTile(
                        value: "marin",
                        groupValue: group.type,
                        onChanged: (v) => controller.setType(v!),
                        title: const Text("Marin"),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= UNITES =================
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Unités",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    showAddUnitDialog(context, controller),
                                icon: const Icon(Icons.add),
                              ),

                              // 🔥 NOUVEAU BOUTON
                              IconButton(
                                tooltip: "Ajouter unités par défaut",
                                onPressed: () =>
                                    controller.createDefaultUnitsIfEmpty(),
                                icon: const Icon(Icons.auto_fix_high),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ...group.units.map((u) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade100,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(u.color),
                            ),
                            title: Text(
                              u.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text("Type : ${u.type.name}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => controller.removeUnit(u.id),
                            ),
                            onTap: () =>
                                showEditUnitDialog(context, controller, u),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Ask new password
  Future<String?> askPassword(BuildContext context) async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nouveau mot de passe"),
        content: TextField(
          obscureText: true,
          controller: controller,
          decoration: const InputDecoration(labelText: "Mot de passe"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }
}

Future<void> showAddUnitDialog(BuildContext context, dynamic controller) async {
  await showDialog(
    context: context,
    builder: (_) => UnitDialog(
      onSubmit: (name, type, color) =>
          controller.addUnit(name: name, type: type, color: color.toARGB32()),
      unit: null,
    ),
  );
}

Future<void> showEditUnitDialog(
  BuildContext context,
  dynamic controller,
  GroupUnit unit,
) async {
  await showDialog(
    context: context,
    builder: (_) => UnitDialog(
      unit: unit,
      onSubmit: (name, type, color) => controller.updateUnit(
        unit.id,
        name: name,
        color: color.toARGB32(),
        type: type,
      ),
    ),
  );
}

class UnitDialog extends StatefulWidget {
  final GroupUnit? unit;
  final Function(String, Unit, Color) onSubmit;

  const UnitDialog({super.key, required this.unit, required this.onSubmit});

  @override
  State<UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends State<UnitDialog> {
  late TextEditingController name;
  late TextEditingController hex;
  late Unit type;
  Color color = Colors.blue;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.unit?.name ?? "");
    type = Unit.aucun;
    color = widget.unit != null ? Color(widget.unit!.color) : Colors.blue;
    hex = TextEditingController(text: _toHex(color));
  }

  @override
  void dispose() {
    name.dispose();
    hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.unit == null ? "Nouvelle unité" : "Modifier l’unité"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "Nom de l’unité"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hex,
              decoration: const InputDecoration(
                labelText: "Couleur hex",
                hintText: "#FF8300",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final parsed = _tryParseHexColor(value);
                if (parsed != null) {
                  setState(() => color = parsed);
                }
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Aperçu : "),
                const SizedBox(width: 10),
                CircleAvatar(backgroundColor: color),
                TextButton(
                  child: const Text("Choisir"),
                  onPressed: () async {
                    await pickColor(context);
                    hex.text = _toHex(color);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: type,
              decoration: const InputDecoration(labelText: "Type"),
              items: Unit.values
                  .map(
                    (u) => DropdownMenuItem(
                      value: u,
                      child: Text(u.toString().split('.').last),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => type = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () {
            final parsedHex = _tryParseHexColor(hex.text);
            if (parsedHex != null) {
              color = parsedHex;
            }
            widget.onSubmit(name.text, type, color);
            Navigator.pop(context);
          },
          child: const Text("Valider"),
        ),
      ],
    );
  }

  static String _toHex(Color c) {
    final rgb = (c.toARGB32() & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    return '#$rgb';
  }

  static Color? _tryParseHexColor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final cleaned = trimmed
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

  Future<void> pickColor(BuildContext context) async {
    Color temp = color;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Couleur de l’unité"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: color,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            labelTypes: const [],
            portraitOnly: true,
            displayThumbColor: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => color = temp);
              Navigator.pop(context);
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }
}
