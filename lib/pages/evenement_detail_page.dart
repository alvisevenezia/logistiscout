import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

class EvenementDetailPage extends StatelessWidget {
  final Evenement evenement;
  final List<Tente> tentes;
  final Map<int, String> unitesMap;

  const EvenementDetailPage({Key? key, required this.evenement, required this.tentes, required this.unitesMap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tentesAssociees = tentes.where((t) => evenement.tentesAssociees.contains(t.id)).toList();
    final uniteNoms = evenement.unites.map((id) => unitesMap[id] ?? 'Inconnue').join(', ');

    Future<void> envoyerMail() async {
      final TextEditingController destinataireController = TextEditingController(text: 'warletanto@cy-tech.fr');
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Envoyer la liste du matériel'),
          content: TextField(
            controller: destinataireController,
            decoration: const InputDecoration(labelText: 'Adresse e-mail du destinataire'),
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, destinataireController.text.trim()),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      );
      if (result == null || result.isEmpty) return;
      final String destinataire = result;
      final String sujet = Uri.encodeComponent('Matériel pour l\'événement : ${evenement.nom}');
      final StringBuffer corps = StringBuffer();
      corps.writeln('Bonjour,\n\nVoici la liste du matériel associé à l\'événement : ${evenement.nom}');
      corps.writeln('Type : ${evenement.type}');
      corps.writeln('Dates : du ${evenement.date.toLocal().toString().split(' ')[0]} au ${evenement.dateFin.toLocal().toString().split(' ')[0]}');
      corps.writeln('Unité(s) : $uniteNoms');
      corps.writeln('\nMatériel :');
      if (tentesAssociees.isEmpty) {
        corps.writeln('- Aucun matériel associé.');
      } else {
        for (final t in tentesAssociees) {
          corps.writeln('- ${t.nom} (${t.nbPlaces} places, ${t.typeTente}) | État général : ${t.etat} | Remarques : ${t.remarques.isNotEmpty ? t.remarques : "Aucune"}');
        }
      }
      corps.writeln('\nScoutement,\n');
      final String mailto = 'mailto:$destinataire?subject=$sujet&body=${Uri.encodeComponent(corps.toString())}';
      if (await canLaunchUrl(Uri.parse(mailto))) {
        await launchUrl(Uri.parse(mailto));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le client mail.')));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Détail événement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
            tooltip: 'Envoyer la liste du matériel',
            onPressed: envoyerMail,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text('Nom'),
              subtitle: Text(evenement.nom),
            ),
            ListTile(
              title: const Text('Type'),
              subtitle: Text(evenement.type),
            ),
            ListTile(
              title: const Text('Début'),
              subtitle: Text(evenement.date.toLocal().toString().split(' ')[0]),
            ),
            ListTile(
              title: const Text('Fin'),
              subtitle: Text(evenement.dateFin.toLocal().toString().split(' ')[0]),
            ),
            ListTile(
              title: const Text('Unité(s)'),
              subtitle: Text(uniteNoms.isNotEmpty ? uniteNoms : 'Non renseignée'),
            ),
            const Divider(),
            const Text('Matériel associé :', style: TextStyle(fontWeight: FontWeight.bold)),
            ...tentesAssociees.isEmpty
                ? [const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Aucun matériel associé.'),
                  )]
                : tentesAssociees.map((t) => ListTile(
                      leading: const Icon(Icons.cabin),
                      title: Text(t.nom),
                      subtitle: Text('Type : ${t.typeTente}'),
                    )),
          ],
        ),
      ),
    );
  }
}

