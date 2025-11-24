import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller responsible for validating and managing the "Nom du contrôleur" form.
class ControleSaisieNomController extends StateNotifier<String> {
  ControleSaisieNomController() : super('');

  /// Updates the current input value
  void updateNom(String nom) {
    state = nom;
  }

  /// Validates the name input and returns an error message (or null if valid)
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
