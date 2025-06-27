import 'package:flutter/material.dart';
import '../models/models.dart';

class ControleDetailPage extends StatelessWidget {
  final Controle controle;
  final Tente? tente;
  const ControleDetailPage({Key? key, required this.controle, this.tente}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Récupération du nom du contrôleur et du nombre de sardines/piquets
    final nomControleur = controle.checklist['nom_controleur'] ?? '';
    final nbSardines = controle.checklist['Nombre de sardines/piquets'] ?? '';
    // Définition des sections et des labels comme lors de la saisie
    final Map<String, List<String>> sections = {
      'Structure et éléments principaux': [
        "Toile extérieure",
        "Toile intérieure",
        "Sol de tente",
        "Mâts/arceaux",
        "Haubans",
        "Cordes supplémentaires",
        "Sardines / Piquets : Nombre conforme au besoin (compter)",
        "Sardines / Piquets : Forme correcte (non pliée)",
        "Sardines / Piquets : Propres",
      ],
      'Fixations et fermetures': [
        "Fermetures éclair",
        "Œillets / Systèmes de serrage",
        "Crochets ou attaches de haubanage",
      ],
      'Accessoires et rangement': [
        "Housse de rangement",
        "Système de pliage / ficelles d'attache",
        "Fiche d'identification",
      ],
      'État général': [
        "Propreté extérieure et intérieure",
        "Tente sèche",
        "Odeurs",
      ],
    };
    final Map<String, String> explications = {
      'Structure et éléments principaux':
          "Vérifier l'état général de la toile, du sol, des mâts, haubans, cordes et sardines/piquets.",
      'Fixations et fermetures':
          "Contrôler les fermetures éclair, œillets, systèmes de serrage et attaches de haubanage.",
      'Accessoires et rangement':
          "Présence et état de la housse, du système de pliage et de la fiche d'identification.",
      'État général':
          "Propreté, séchage complet et absence d'odeur de moisi.",
    };
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
            if (nomControleur.isNotEmpty)
              ListTile(
                title: const Text('Contrôleur'),
                subtitle: Text(nomControleur),
              ),
            if (nbSardines.toString().isNotEmpty)
              ListTile(
                title: const Text('Nombre de sardines/piquets'),
                subtitle: Text(nbSardines.toString()),
              ),
            ListTile(
              title: const Text('Remarques'),
              subtitle: Text(controle.remarques.isNotEmpty ? controle.remarques : 'Aucune'),
            ),
            const Divider(),
            ...sections.entries.map((section) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.key, style: Theme.of(context).textTheme.titleMedium),
                if (explications[section.key] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      explications[section.key]!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ...section.value.map((label) {
                  final key = 'verifie_valide_$label';
                  final remarqueKey = 'remarque_$label';
                  final checked = controle.checklist[key] == true;
                  final remarque = controle.checklist[remarqueKey]?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          checked ? Icons.check_circle : Icons.cancel,
                          color: checked ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(label)),
                        if (remarque.isNotEmpty)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text('Remarque : $remarque', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            )),
          ],
        ),
      ),
    );
  }
}

