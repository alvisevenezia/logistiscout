import 'package:flutter/material.dart';
import '../models/models.dart';

class ControleDetailPage extends StatelessWidget {
  final Controle controle;
  final Tente? tente;
  const ControleDetailPage({Key? key, required this.controle, this.tente}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du contrôle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (tente != null)
              ListTile(
                title: const Text('Tente'),
                subtitle: Text(tente!.nom),
              ),
            ListTile(
              title: const Text('Date'),
              subtitle: Text('${controle.date.day}/${controle.date.month}/${controle.date.year}'),
            ),
            ListTile(
              title: const Text('Remarques'),
              subtitle: Text(controle.remarques.isNotEmpty ? controle.remarques : 'Aucune'),
            ),
            const Divider(),
            const Text('Checklist', style: TextStyle(fontWeight: FontWeight.bold)),
            ...controle.checklist.entries.map((e) {
              if (e.value is bool) {
                return ListTile(
                  leading: Icon(
                    e.value == true ? Icons.check_circle : Icons.cancel,
                    color: e.value == true ? Colors.green : Colors.red,
                  ),
                  title: Text(e.key),
                );
              } else {
                return ListTile(
                  title: Text(e.key),
                  subtitle: Text(e.value.toString()),
                );
              }
            }).toList(),
          ],
        ),
      ),
    );
  }
}



