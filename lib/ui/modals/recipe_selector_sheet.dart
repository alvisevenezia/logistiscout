import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/recipe.dart';

class RecipeSelectorResult {
  final List<Recipe> recipes;
  const RecipeSelectorResult(this.recipes);
}

class RecipeSelectorSheet extends StatefulWidget {
  final List<Recipe> all;
  const RecipeSelectorSheet({super.key, required this.all});

  @override
  State<RecipeSelectorSheet> createState() => _RecipeSelectorSheetState();
}

class _RecipeSelectorSheetState extends State<RecipeSelectorSheet> {
  final Set<String> _selectedIds = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.all
        .where((r) => r.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des recettes'),
        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () {
              final selected = widget.all
                  .where((r) => _selectedIds.contains(r.id))
                  .toList();
              Navigator.pop(context, RecipeSelectorResult(selected));
            },
            child: Text(
              'Ajouter (${_selectedIds.length})',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher une recette...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final r = filtered[i];
                final selected = _selectedIds.contains(r.id);
                return CheckboxListTile(
                  title: Text(r.title),
                  subtitle: Text(r.category.name),
                  value: selected,
                  onChanged: (_) {
                    setState(() {
                      if (selected) {
                        _selectedIds.remove(r.id);
                      } else {
                        _selectedIds.add(r.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
