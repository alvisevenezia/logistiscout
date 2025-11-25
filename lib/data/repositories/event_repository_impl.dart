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

class EventRepositoryImpl implements EventRepository {
  final ApiService api;

  EventRepositoryImpl(this.api);

  Future<void> addEvent(Event event) async {
    final dto = EventMapper.toDto(event);
    await api.addEvent(dto.toJson());
  }

  @override
  Future<void> updateEvent(Event event) async {
    developer.log('[EventRepository] 🔄 updateEventTentes(eventId=${event.id})');
    final dto = EventMapper.toDto(event);
    await api.updateEvent(dto.id, dto.toJson());
  }

  Future<void> deleteEvent(int id, String groupeId) async {
    await api.deleteEvent(id, groupId: groupeId);
  }

  @override
  Future<void> updateEventTents(String groupId, int eventId,
      List<int> tentIds, Event event) async {
    developer.log('[EventRepository] 🔄 updateEventTentes(eventId=$eventId)');

    final evt = {
      'groupeId': groupId,
      'nom': event.nom,
      'type': event.type,
      'date': event.date.toIso8601String(),
      'dateFin': event.dateFin.toIso8601String(),
      'unites': event.unites,
      'tentesAssociees': tentIds,
    };

    await api.updateEvent(eventId, evt);
  }

  @override
  Future<List<Event>> getAllEvents() async {
    final groupId = await LocalStorageService.instance.getGroupId();
    if (groupId == null || groupId.isEmpty) {
      throw Exception('GroupId is null or empty');
    }

    developer.log(
        '[EventRepositoryImpl] 🔍 Fetching all events for groupId=$groupId');

    final data = await api.getEventList(groupId);

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
    final all = await api.getEventList(groupId);
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
      associatedTents: List<int>.from(data['tentesAssociees'] ?? []),
      unites: List<int>.from(data['unites'] ?? []),
      groupId: data['groupeId'],
    );
  }

  // === 📅 Menus planifiés (EventMenus) ===
  @override
  Future<MealPlan> getMealPlan(String eventId, DateTime date, MealType meal) async {
    // 🔹 Get all event_menu rows for this event
    final all = await api.getEventMenuList(int.parse(eventId));

    // 🔹 Filter only those matching the selected date & meal
    final dateStr = date.toIso8601String().split('T').first;
    final matching = all.where((m) =>
    m['date'] == dateStr &&
        m['type_repas'] == meal.name).toList();

    final items = <MenuItem>[];

    for (final m in matching) {
      try {
        final eventMenuId = m['id']; // relation ID
        final menuId = m['menu_id']; // actual recipe/menu ID
        if (menuId == null) continue;

        // 🔹 Get menu (recipe) details from /menus/{id}
        final menuData = await api.getMenu(menuId);

        final ingredientsData = (menuData['ingredients'] as List?) ?? [];
        final ingredients = ingredientsData.map((i) {
          return IngredientTotal(
            name: i['nom'] ?? 'Ingrédient inconnu',
            quantity: (i['quantite'] as num?)?.toDouble() ?? 0,
            unit: i['unite'] ?? '',
          );
        }).toList();

        // 🔹 Map menu → Recipe entity
        final recipe = Recipe(
          id: menuData['id'].toString(),
          title: menuData['nom'] ?? 'Recette inconnue',
          description: menuData['description'] ?? '',
          instructions: menuData['instructions'] ?? '',
          category: RecipeCategory.plat,
          ingredients: ingredients,
        );

        // 🔹 Build MenuItem with both IDs
        items.add(MenuItem(
          eventMenuId: eventMenuId,
          menuId: menuId,
          recipe: recipe,
          baseIngredients: ingredients,
        ));
      } catch (e, st) {
        developer.log(
          '[EventRepositoryImpl] ⚠️ Failed to load menu ${m['menu_id']}: $e',
          stackTrace: st,
        );
      }
    }

    return MealPlan(
      date: date,
      meal: meal,
      portions: matching.isNotEmpty
          ? (matching.first['quantite_personnes'] ?? 1)
          : 1,
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
  Future<void> updateEventMenu(
      int eventMenuId, int eventId, int menuId, DateTime date, MealType meal, int quantity) async {
    final payload = {
      'event_id': eventId,
      'menu_id': menuId,
      'date': date.toIso8601String().split('T').first,
      'type_repas': meal.name,
      'quantite_personnes': quantity,
    };

    await api.updateEventMenu(eventMenuId, payload);
  }

  @override
  Future<void> addEventMenu({
    required int eventId,
    required int menuId,
    required DateTime date,
    required MealType meal,
    required int portions,
  }) async {
    await api.addEventMenu({
      'event_id': eventId,
      'menu_id': menuId,
      'date': date.toIso8601String().split('T').first,
      'type_repas': meal.name,
      'quantite_personnes': portions,
    });
  }

  @override
  Future<void> deleteEventMenu(int eventMenuId) async {
    await api.deleteEventMenu(eventMenuId);
  }


}
