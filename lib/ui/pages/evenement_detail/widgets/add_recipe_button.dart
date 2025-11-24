// lib/ui/pages/menus/add_recipe_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/ui/pages/evenement_detail/recipe_actions.dart';

class AddRecipeButton extends ConsumerWidget {
  final String eventId;
  const AddRecipeButton({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Ajouter / Créer une recette'),
          onPressed: () => _openAddRecipeMenu(context, ref),
        ),
      ),
    );
  }

  void _openAddRecipeMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: const Text('Choisir parmi les recettes existantes'),
                  onTap: () {
                    Navigator.pop(context);
                    openRecipeSelector(context, ref, eventId); // ⬅️
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Créer une nouvelle recette'),
                  onTap: () {
                    Navigator.pop(context);
                    openRecipeCreator(context, ref, eventId); // ⬅️
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Annuler'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
