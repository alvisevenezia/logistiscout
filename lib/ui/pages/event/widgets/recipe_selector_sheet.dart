import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/recipe.dart';

class RecipeSelectorSheet extends StatefulWidget {
  final List<Recipe> recipes;
  final Set<int> existingIds;

  const RecipeSelectorSheet({super.key,
    required this.recipes,
    required this.existingIds,
  });

  @override
  State<RecipeSelectorSheet> createState() => RecipeSelectorSheetState();
}

class RecipeSelectorSheetState extends State<RecipeSelectorSheet> {
  final Set<int> _selectedIds = {};
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.recipes
        .where((r) => r.title.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Text(
            'Sélectionner des recettes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher une recette...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Aucune recette trouvée'))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final recipe = filtered[i];
                final selected = _selectedIds.contains(recipe.id);
                final isExisting = widget.existingIds.contains(recipe.id);

                return Opacity(
                  opacity: isExisting ? 0.5 : 1.0,
                  child: Card(
                    elevation: selected ? 4 : 1,
                    color: selected
                        ? Colors.green.shade50
                        : Colors.grey.shade50,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          recipe.title.isNotEmpty
                              ? recipe.title[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        recipe.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isExisting
                            ? 'Déjà ajouté à ce repas'
                            : recipe.menuType.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isExisting
                              ? Colors.red.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                      trailing: Icon(
                        isExisting
                            ? Icons.block
                            : selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isExisting
                            ? Colors.red
                            : selected
                            ? Colors.green
                            : Colors.grey,
                      ),
                      onTap: isExisting
                          ? null
                          : () {
                        setState(() {
                          if (selected) {
                            _selectedIds.remove(recipe.id);
                          } else {
                            _selectedIds.add(recipe.id);
                          }
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text(
              _selectedIds.isEmpty
                  ? 'Aucune sélection'
                  : 'Ajouter ${_selectedIds.length} recette(s)',
            ),
            onPressed: _selectedIds.isEmpty
                ? null
                : () {
              final selectedRecipes = widget.recipes
                  .where((r) => _selectedIds.contains(r.id))
                  .toList();
              Navigator.pop(context, selectedRecipes);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
