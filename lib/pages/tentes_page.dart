import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/api_service.dart';
import 'tente_detail.dart';

class TentesPage extends StatefulWidget {
  const TentesPage({super.key});
  @override
  State<TentesPage> createState() => _TentesPageState();
}

class _TentesPageState extends State<TentesPage> {
  List<Tente> tentes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTentes();
  }

  Future<void> _loadTentes() async {
    final groupeId = await _getGroupeId();
    final data = await ApiService.getTentes(groupeId);
    final futures = data.map<Future<Tente>>((json) => Tente.fromApiJson(json)).toList();
    final loadedTentes = await Future.wait(futures);
    loadedTentes.sort((a, b) => a.nom.compareTo(b.nom));
    setState(() {
      tentes = loadedTentes;
      isLoading = false;
    });
  }

  Future<String> _getGroupeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('groupeId') ?? '';
  }

  Future<void> _ajouterTente() async {
    final nomController = TextEditingController();
    bool tapisSolIntegre = false;
    String typeTente = 'Canadienne';
    int nbPlaces = 6;
    String unitePreferee = '';
    String etat = 'Bon';
    final List<String> types = ['Canadienne', 'Tipi', 'Autre'];
    final List<Color> couleurs = [];
    Color? couleurSelectionnee;
    // Liste fixe des unités SGDF
    final List<String> unitesNoms = [
      'Farfadet',
      'Louveteaux-Jeannettes',
      'Scout-Guide',
      'Pionnier-Caravelle',
      'Compagnon',
    ];
    if (unitesNoms.isNotEmpty) unitePreferee = unitesNoms.first;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nouvelle tente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: 'Nom de la tente'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: typeTente,
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      typeTente = val!;
                      if (typeTente == 'Canadienne') {
                        nbPlaces = 6;
                      } else if (typeTente == 'Tipi') {
                        nbPlaces = 8;
                      }
                      else {
                        nbPlaces = 0;
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Type de tente'),
                ),
                const SizedBox(height: 8),
                if (typeTente == 'Canadienne')
                  DropdownButtonFormField<int>(
                    value: [4, 5, 6, 7, 8].contains(nbPlaces) ? nbPlaces : 4,
                    items: [4, 5, 6, 7, 8]
                        .map((n) => DropdownMenuItem(value: n, child: Text('$n places')))
                        .toList(),
                    onChanged: (val) => setStateDialog(() => nbPlaces = val ?? 4),
                    decoration: const InputDecoration(labelText: 'Nombre de places'),
                  )
                else if (typeTente == 'Tipi')
                  DropdownButtonFormField<int>(
                    value: nbPlaces,
                    items: [8, 10, 12].map((n) => DropdownMenuItem(value: n, child: Text('$n places'))).toList(),
                    onChanged: (val) => setStateDialog(() => nbPlaces = val ?? 8),
                    decoration: const InputDecoration(labelText: 'Nombre de places'),
                  )
                else
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nombre de places'),
                    onChanged: (val) => nbPlaces = int.tryParse(val) ?? 0,
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: tapisSolIntegre,
                  onChanged: (val) => setStateDialog(() => tapisSolIntegre = val),
                  title: const Text('Tapis de sol intégré'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: unitePreferee.isNotEmpty ? unitePreferee : null,
                  items: unitesNoms.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (val) => setStateDialog(() => unitePreferee = val ?? ''),
                  decoration: const InputDecoration(labelText: 'Unité préférée'),
                ),
                const SizedBox(height: 8),
                // Ajout du choix de l'état de la tente
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: 'Bon',
                  items: ['Bon', 'À réparer', 'HS', 'Perdue']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    // Stocker la valeur dans une variable locale
                    if (val != null) {
                      setStateDialog(() {
                        etat = val;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'État de la tente'),
                ),
                const SizedBox(height: 8),
                // Gestion des couleurs (scotch)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...couleurs.map((c) => Chip(
                        label: Text('#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}'),
                        backgroundColor: c,
                        labelStyle: TextStyle(
                          color: ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : Colors.black,
                        ),
                        onDeleted: () {
                          setStateDialog(() => couleurs.remove(c));
                        },
                      )),
                      GestureDetector(
                        onTap: () async {
                          Color tempColor = couleurSelectionnee ?? Colors.blue;
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Choisir une couleur'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: tempColor,
                                  onColorChanged: (color) {
                                    tempColor = color;
                                  },
                                  enableAlpha: false,
                                  pickerAreaHeightPercent: 0.7,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Annuler'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                ElevatedButton(
                                  child: const Text('Valider'),
                                  onPressed: () {
                                    setStateDialog(() {
                                      couleurSelectionnee = tempColor;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: couleurSelectionnee ?? Colors.grey.shade300,
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: couleurSelectionnee != null
                              ? Center(
                                  child: Text(
                                    '#${couleurSelectionnee!.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                                    style: const TextStyle(fontSize: 10, color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : const Icon(Icons.add, size: 20, color: Colors.black45),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, size: 20),
                        tooltip: 'Ajouter la couleur',
                        onPressed: () {
                          if (couleurSelectionnee != null) {
                            final exists = couleurs.any((c) => c.toARGB32() == couleurSelectionnee!.toARGB32());
                            if (!exists) {
                              setStateDialog(() {
                                couleurs.add(couleurSelectionnee!);
                                couleurSelectionnee = null;
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
    final groupeId = await _getGroupeId();
    if (result == true && nomController.text.isNotEmpty) {
      await ApiService.addTente({
        'nom': nomController.text,
        'uniteId': null,
        'etat': etat,
        'remarques': '',
        'tapisSolIntegre': tapisSolIntegre,
        'nbPlaces': nbPlaces,
        'typeTente': typeTente,
        'unitePreferee': unitePreferee,
        'couleurs': couleurs.map((c) => '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}').toList(),
        'groupeId': groupeId,
      });
      await _loadTentes();
    }
  }

  Future<void> _modifierTente(Tente tente) async {
    final nomController = TextEditingController(text: tente.nom);
    bool tapisSolIntegre = tente.tapisSolIntegre;
    String typeTente = tente.typeTente;
    int nbPlaces = tente.nbPlaces;
    String unitePreferee = tente.unitePreferee;
    String etat = tente.etat;
    final List<String> types = ['Canadienne', 'Tipi', 'Autre'];
    final List<Color> couleurs = List<Color>.from(
      tente.couleurs.map((c) => _parseColor(c)),
    );
    Color? couleurSelectionnee;
    final List<String> unitesNoms = [
      'Farfadet',
      'Louveteaux-Jeannettes',
      'Scout-Guide',
      'Pionnier-Caravelle',
      'Compagnon',
    ];
    if (unitesNoms.isNotEmpty && unitePreferee.isEmpty) unitePreferee = unitesNoms.first;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Modifier la tente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: 'Nom de la tente'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: typeTente,
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      typeTente = val!;
                      if (typeTente == 'Canadienne') {
                        nbPlaces = 6;
                      } else if (typeTente == 'Tipi') {
                        nbPlaces = 8;
                      }
                      else {
                        nbPlaces = 0;
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Type de tente'),
                ),
                const SizedBox(height: 8),
                if (typeTente == 'Canadienne')
                  DropdownButtonFormField<int>(
                    value: [4, 5, 6, 7, 8].contains(nbPlaces) ? nbPlaces : 4,
                    items: [4, 5, 6, 7, 8]
                        .map((n) => DropdownMenuItem(value: n, child: Text('$n places')))
                        .toList(),
                    onChanged: (val) => setStateDialog(() => nbPlaces = val ?? 4),
                    decoration: const InputDecoration(labelText: 'Nombre de places'),
                  )
                else if (typeTente == 'Tipi')
                  DropdownButtonFormField<int>(
                    value: nbPlaces,
                    items: [8, 10, 12].map((n) => DropdownMenuItem(value: n, child: Text('$n places'))).toList(),
                    onChanged: (val) => setStateDialog(() => nbPlaces = val ?? 8),
                    decoration: const InputDecoration(labelText: 'Nombre de places'),
                  )
                else
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nombre de places'),
                    onChanged: (val) => nbPlaces = int.tryParse(val) ?? 0,
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: tapisSolIntegre,
                  onChanged: (val) => setStateDialog(() => tapisSolIntegre = val),
                  title: const Text('Tapis de sol intégré'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: unitePreferee.isNotEmpty ? unitePreferee : null,
                  items: unitesNoms.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (val) => setStateDialog(() => unitePreferee = val ?? ''),
                  decoration: const InputDecoration(labelText: 'Unité préférée'),
                ),
                const SizedBox(height: 8),
                // Ajout du choix de l'état de la tente lors de la modification
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: etat,
                  items: ['Bon', 'À réparer', 'HS', 'Perdue']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateDialog(() {
                        etat = val;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'État de la tente'),
                ),
                const SizedBox(height: 8),
                // Gestion des couleurs (scotch)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...couleurs.map((c) => Chip(
                        label: Text('#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}'),
                        backgroundColor: c,
                        labelStyle: TextStyle(
                          color: ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : Colors.black,
                        ),
                        onDeleted: () {
                          setStateDialog(() => couleurs.remove(c));
                        },
                      )),
                      GestureDetector(
                        onTap: () async {
                          Color tempColor = couleurSelectionnee ?? Colors.blue;
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Choisir une couleur'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: tempColor,
                                  onColorChanged: (color) {
                                    tempColor = color;
                                  },
                                  enableAlpha: false,
                                  pickerAreaHeightPercent: 0.7,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Annuler'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                ElevatedButton(
                                  child: const Text('Valider'),
                                  onPressed: () {
                                    setStateDialog(() {
                                      couleurSelectionnee = tempColor;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: couleurSelectionnee ?? Colors.grey.shade300,
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: couleurSelectionnee != null
                              ? Center(
                                  child: Text(
                                    '#${couleurSelectionnee!.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                                    style: const TextStyle(fontSize: 10, color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : const Icon(Icons.add, size: 20, color: Colors.black45),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, size: 20),
                        tooltip: 'Ajouter la couleur',
                        onPressed: () {
                          if (couleurSelectionnee != null) {
                            final exists = couleurs.any((c) => c.toARGB32() == couleurSelectionnee!.toARGB32());
                            if (!exists) {
                              setStateDialog(() {
                                couleurs.add(couleurSelectionnee!);
                                couleurSelectionnee = null;
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    final groupeId = await _getGroupeId();
    if (result == true && nomController.text.isNotEmpty) {
      await ApiService.updateTente(tente.id, {
        'nom': nomController.text,
        'uniteId': tente.uniteId,
        'etat': etat,
        'remarques': tente.remarques,
        'estIntegree': tapisSolIntegre,
        'nbPlaces': nbPlaces,
        'typeTente': typeTente,
        'unitePreferee': unitePreferee,
        'couleurs': couleurs.map((c) => '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}').toList(),
        'groupeId': groupeId,
      });
      await _loadTentes();
    }
  }

  Future<void> _supprimerTente(int id) async {
    final groupeId = await _getGroupeId();
    await ApiService.deleteTente(id, groupeId: groupeId);
    _loadTentes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentes')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tentes.isEmpty
              ? const Center(child: Text('Aucune tente enregistrée.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: tentes.length,
                  itemBuilder: (context, index) {
                    final tente = tentes[index];
                    final Color etatColor;
                    switch (tente.etat.toLowerCase()) {
                      case 'bon':
                        etatColor = Colors.green.shade100;
                        break;
                      case 'à réparer':
                        etatColor = Colors.orange.shade100;
                        break;
                      case 'hs':
                        etatColor = Colors.red.shade100;
                        break;
                      case 'perdue':
                        etatColor = Colors.grey.shade400;
                        break;
                      default:
                        etatColor = Colors.grey.shade200;
                    }
                    return Stack(
                      children: [
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          color: etatColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.blue.shade100, width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(Icons.cabin, color: Color(0xFF003a5d)),
                            ),
                            title: Text(
                              tente.nom,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('État : ${tente.etat}', style: const TextStyle(fontSize: 14)),
                                Text('Unité : ${tente.unitePreferee}', style: const TextStyle(fontSize: 13)),
                                if (tente.historiqueControles.isNotEmpty)
                                  Text('Dernier contrôle : ${tente.historiqueControles.last.date.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.push<Tente>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TenteDetailPage(tente: tente),
                                ),
                              );
                              await _loadTentes();
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tente.tapisSolIntegre)
                                  const Tooltip(
                                    message: 'Tapis de sol intégrée',
                                    child: Icon(Icons.check_circle, color: Colors.green, size: 22),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Modifier',
                                  onPressed: () => _modifierTente(tente),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Supprimer la tente'),
                                        content: Text('Supprimer ${tente.nom} ?'),
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
                                    if (confirm == true) {
                                      _supprimerTente(tente.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Affichage des rectangles de couleur en haut à droite
                        if (tente.couleurs.isNotEmpty)
                          Positioned(
                            top: 10,
                            right: 18,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: tente.couleurs.take(5).map<Widget>((couleur) => Container(
                                width: 18,
                                height: 10,
                                margin: const EdgeInsets.only(left: 2),
                                decoration: BoxDecoration(
                                  color: _parseColor(couleur),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                              )).toList(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterTente,
        tooltip: 'Ajouter une tente',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Ajout de la fonction utilitaire pour parser une couleur depuis un string
  Color _parseColor(String couleur) {
    try {
      if (couleur.startsWith('#')) {
        return Color(int.parse(couleur.substring(1), radix: 16) + 0xFF000000);
      }
      // Prise en charge des noms de couleurs simples
      switch (couleur.toLowerCase()) {
        case 'rouge':
          return Colors.red;
        case 'vert':
          return Colors.green;
        case 'bleu':
          return Colors.blue;
        case 'jaune':
          return Colors.yellow;
        case 'orange':
          return Colors.orange;
        case 'violet':
          return Colors.purple;
        case 'noir':
          return Colors.black;
        case 'blanc':
          return Colors.white;
        case 'gris':
          return Colors.grey;
        default:
          return Colors.grey.shade400;
      }
    } catch (e) {
      return Colors.grey.shade400;
    }
  }
}
