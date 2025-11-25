import 'package:flutter_riverpod/flutter_riverpod.dart';

class ControleSaisieNomController extends StateNotifier<String> {
  ControleSaisieNomController() : super('');

  void updateNom(String nom) {
    state = nom;
  }

  String? validateNom() {
    if (state.trim().isEmpty) {
      return 'Veuillez saisir un nom.';
    }
    if (state.length < 2) {
      return 'Nom trop court.';
    }
    return null;
  }
}

final controleSaisieNomProvider =
StateNotifierProvider<ControleSaisieNomController, String>(
      (ref) => ControleSaisieNomController(),
);
