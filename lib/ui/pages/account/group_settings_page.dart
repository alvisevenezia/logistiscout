import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:logistiscout/core/di.dart';
import 'dart:developer' as developer;

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
      appBar: AppBar(title: const Text("Paramètres du groupe")),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Erreur: $e")),
        data: (group) {
          developer.log("group loaded: ${group.name}");

          final nameController = TextEditingController(text: group.name);
          final emailController = TextEditingController(text: group.email);
          final loginController = TextEditingController(text: group.login);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // === INFOS GENERALES ===
              const Text("Informations générales",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nom du groupe"),
                onChanged: controller.setName,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                onChanged: controller.setEmail,
              ),
              TextField(
                controller: loginController,
                decoration: const InputDecoration(labelText: "Identifiant (login)"),
                onChanged: controller.setLogin,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final newPwd = await askPassword(context);
                  if (newPwd != null) controller.setPassword(newPwd);
                },
                child: const Text("Changer le mot de passe"),
              ),

              const SizedBox(height: 30),

              // === TYPE DE GROUPE ===
              const Text("Type de groupe",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              RadioListTile(
                title: const Text("Groupe Scout"),
                value: "scout",
                groupValue: group.type,
                onChanged: (v) => controller.setType(v!),
              ),
              RadioListTile(
                title: const Text("Groupe Marin"),
                value: "marin",
                groupValue: group.type,
                onChanged: (v) => controller.setType(v!),
              ),

              const SizedBox(height: 30),

              // === UNITES ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Unités",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => showAddUnitDialog(context, controller),
                    icon: const Icon(Icons.add),
                  )
                ],
              ),

              Column(
                children: group.units.map((u) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Color(u.color) ),
                      title: Text(u.name),
                      subtitle: Text("Type : ${u.type}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => controller.removeUnit(u.id),
                      ),
                      onTap: () =>
                          showEditUnitDialog(context, controller, u),
                    ),
                  );
                }).toList(),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }
}

/// === DIALOGS UNITÉS ===

Future<void> showAddUnitDialog(BuildContext context, dynamic controller) async {
  await showDialog(
    context: context,
    builder: (_) => UnitDialog(
      onSubmit: (name, type, color) =>
          controller.addUnit(name: name, type: type, color: color),
    ),
  );
}

Future<void> showEditUnitDialog(
    BuildContext context, dynamic controller, dynamic unit) async {
  await showDialog(
    context: context,
    builder: (_) => UnitDialog(
      unit: unit,
      onSubmit: (name, type, color) =>
          controller.updateUnit(unit.id, name: name, type: type, color: color),
    ),
  );
}

/// Dialog générique pour unité
class UnitDialog extends StatefulWidget {
  final dynamic unit;
  final Function(String, String, Color) onSubmit;

  const UnitDialog({super.key, this.unit, required this.onSubmit});

  @override
  State<UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends State<UnitDialog> {
  late TextEditingController name;
  late String type;
  Color color = Colors.blue;

  final List<String> predefinedTypes = [
    "Louveteaux",
    "Éclaireurs",
    "Pionniers",
    "Compagnons",
    "Marins"
  ];

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.unit?.name ?? "");
    type = widget.unit?.type ?? predefinedTypes.first;
    color = widget.unit?.color ?? Colors.blue;
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
            DropdownButtonFormField(
              value: type,
              decoration: const InputDecoration(labelText: "Type"),
              items: predefinedTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => type = v!),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Text("Couleur : "),
                const SizedBox(width: 10),
                CircleAvatar(backgroundColor: color),
                TextButton(
                  child: const Text("Changer"),
                  onPressed: () => pickColor(context),
                )
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(name.text, type, color);
            Navigator.pop(context);
          },
          child: const Text("Valider"),
        ),
      ],
    );
  }

  Future<void> pickColor(BuildContext context) async {
    Color temp = color;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Couleur de l’unité"),
        content: BlockPicker(
          pickerColor: color,
          onColorChanged: (c) => temp = c,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              setState(() => color = temp);
              Navigator.pop(context);
            },
            child: const Text("Valider"),
          )
        ],
      ),
    );
  }
}