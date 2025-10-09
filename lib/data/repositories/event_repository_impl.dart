import 'dart:convert';
import 'package:logistiscout/data/mappers/event_mapper.dart';
import 'package:logistiscout/data/models/event_dto.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/menu.dart';
import 'package:logistiscout/domain/entities/recipe.dart';
import 'package:logistiscout/domain/repositories/event_repository.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'dart:developer' as developer;

import '../../domain/entities/ingredient.dart';

/// Implémentation concrète du EventRepository.
/// Connecte les use cases au backend FastAPI via ApiService.
class EventRepositoryImpl implements EventRepository {
  final ApiService api;

  EventRepositoryImpl(this.api);

  // === ⚙️ Événements ===

  Future<List<Event>> getAllEvents() async {
    final groupId = await LocalStorageService.instance.getGroupId();
    if (groupId == null || groupId.isEmpty) {
      throw Exception('GroupId is null or empty');
    }

    developer.log(
        '[EventRepositoryImpl] 🔍 Fetching all events for groupId=$groupId');

    final data = await api.getEvenements(groupId);

    if (data.isEmpty) {
      developer.log(
          '[EventRepositoryImpl] ⚠️ No events found for groupId=$groupId');
      return [];
    }

    developer.log(
        '[EventRepositoryImpl] ✅ ${data.length} events loaded from API');

    return data.map<Event>((json) {
      try {
        return EventMapper.toDomain(EventDto.fromJson(json));
      } catch (err, st) {
        developer.log(
            '[EventRepositoryImpl] ❌ Failed to map event $json', error: err,
            stackTrace: st);
        rethrow;
      }
    }).toList();
  }

  @override
  Future<Event> getEvent(String id) async {
    final groupId = await LocalStorageService.instance.getGroupId();
    if (groupId == null) {
      throw Exception('GroupId is null');
    }
    final all = await api.getEvenements(groupId);
    final data = all.firstWhere(
          (e) => e['id'].toString() == id,
      orElse: () => throw Exception('Événement $id introuvable'),
    );
    return Event(
      id: data['id'],
      nom: data['nom'],
      date: DateTime.parse(data['date']),
      dateFin: DateTime.parse(data['dateFin']),
      type: data['type'],
      tentesAssociees: List<int>.from(data['tentesAssociees'] ?? []),
      unites: List<int>.from(data['unites'] ?? []),
      groupeId: data['groupe_id'],
    );
  }

  // === 📅 Menus planifiés (EventMenus) ===
  @override
  @override
  Future<MealPlan> getMealPlan(String eventId, DateTime date, MealType meal) async {
    final all = await api.getEventMenus(int.parse(eventId));

    final matching = all.where((m) =>
    m['date'] == date.toIso8601String().split('T').first &&
        m['type_repas'] == meal.name).toList();

    // 🔹 On crée un item pour chaque correspondance
    final items = <MenuItem>[];

    for (final m in matching) {
      final menuData = m['menu'] ?? m; // si l'API imbrique ou non le menu

      // ⚙️ Récupération sécurisée des ingrédients
      final rawIngredients = (menuData['ingredients'] ?? []) as List;
      final ingredients = rawIngredients
          .map((i) => IngredientTotal(
        name: i['nom'] ?? 'Ingrédient inconnu',
        quantity: (i['quantite'] as num?)?.toDouble() ?? 0,
        unit: i['unite'] ?? '',
      ))
          .toList();

      // ⚙️ Récupération sécurisée des infos de recette
      final recipe = Recipe(
        id: (menuData['id'] ?? m['menu_id'] ?? '0').toString(),
        title: menuData['nom'] ?? 'Recette inconnue',
        category: RecipeCategory.plat,
      );

      items.add(MenuItem(recipe: recipe, baseIngredients: ingredients));
    }

    // 🔹 Quantité/personnes
    final portions = matching.isNotEmpty
        ? (matching.first['quantite_personnes'] ?? 1)
        : 1;

    return MealPlan(
      date: date,
      meal: meal,
      portions: portions,
      items: items,
    );
  }


  @override
  Future<void> saveMealPlan(String eventId, MealPlan plan) async {
    // On reconstruit un body conforme au backend
    for (final item in plan.items) {
      final body = {
        'event_id': int.parse(eventId),
        'menu_id': int.parse(item.recipe.id),
        'date': plan.date
            .toIso8601String()
            .split('T')
            .first,
        'type_repas': plan.meal.name,
        'quantite_personnes': plan.portions,
      };
      await api.addEventMenu(body);
    }
  }

  @override
  Future<void> duplicateMealPlans(String eventId,
      MealPlan source,
      List<MapEntry<DateTime, MealType>> targets,) async {
    for (final target in targets) {
      for (final item in source.items) {
        final body = {
          'event_id': int.parse(eventId),
          'menu_id': int.parse(item.recipe.id),
          'date': target.key
              .toIso8601String()
              .split('T')
              .first,
          'type_repas': target.value.name,
          'quantite_personnes': source.portions,
        };
        await api.addEventMenu(body);
      }
    }
  }

  @override
  Future<void> deleteEventMenu(int eventMenuId) async {
    await api.deleteEventMenu(eventMenuId);
  }

  Future<void> updateEventTentes(String groupId, int eventId,
      List<int> tenteIds, Event event) async {
    developer.log('[EventRepository] 🔄 updateEventTentes(eventId=$eventId)');

    final evt = {
      'groupeId': groupId,
      'nom': event.nom,
      'type': event.type,
      'date': event.date.toIso8601String(),
      'dateFin': event.dateFin.toIso8601String(),
      'unites': event.unites,
      'tentesAssociees': tenteIds,
    };

    await api.updateEvenement(eventId, evt);
  }
}
