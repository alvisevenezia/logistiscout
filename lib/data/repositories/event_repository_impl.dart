import 'package:logistiscout/data/mappers/event_mapper.dart';
import 'package:logistiscout/data/mappers/menu_item_mapper.dart';
import 'package:logistiscout/data/models/event_dto.dart';
import 'package:logistiscout/data/models/menu_item_dto.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/menu.dart';
import 'package:logistiscout/domain/entities/unit.dart';
import 'package:logistiscout/domain/repositories/event_repository.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'dart:developer' as developer;

class EventRepositoryImpl implements EventRepository {
  final ApiService api;

  EventRepositoryImpl(this.api);

  @override
  Future<void> createEvent(Event event) async {
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
      'unites': event.unites.map((u) => Unit.toInt(u)).toList(),
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

    final data = await api.getEventList();

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
  Future<Event> getEvent(int id) async {
    final all = await api.getEventList();
    final data = all.firstWhere(
          (e) => e['id'] == id,
      orElse: () => throw Exception('Événement $id introuvable'),
    );
    return Event(
      id: data['id'],
      nom: data['nom'],
      date: DateTime.parse(data['date']),
      dateFin: DateTime.parse(data['dateFin']),
      type: data['type'],
      associatedTents: List<int>.from(data['tentesAssociees'] ?? []),
      unites: (data['unites'] as List<dynamic>? ?? [])
          .map((u) => Unit.fromInt(u))
          .toList(),
      groupId: data['groupeId'].toString(),
    );
  }

  @override
  Future<MealPlan> getMealPlan(int eventId, int dayNumber, MealType meal) async {

    final all = await api.getEventMealPlanList(eventId).then(
          (data) => data
          .map<MenuItem>((json) => menuItemDtoToDomain(MenuItemDto.fromJson(json)))
          .toList(),
    );

    final matching = all.where((currentMenuItemDto) =>
    currentMenuItemDto.dayNumber == dayNumber &&
        currentMenuItemDto.mealType == meal).toList();


    return MealPlan(
      dayNumber: dayNumber,
      mealType: meal,
      portions: matching.isNotEmpty
          ? (matching.first.portions)
          : 1,
      items: matching,
      eventId: eventId,
    );
  }



  @override
  Future<void> saveMealPlan(String eventId, MealPlan plan) async {
    for (final item in plan.items) {
      final body = {
        'event_id': int.parse(eventId),
        'menu_id': item.recipeId,
        'day_number': plan.portions,
        'type_repas': plan.mealType.name,
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
          'menu_id': item.recipeId,
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
      int eventMenuId, int eventId, int menuId, int dayNumber, MealType meal, int quantity) async {
    final payload = {
      'event_id': eventId,
      'menu_id': menuId,
      'day_number': dayNumber,
      'type_repas': meal.name,
      'quantite_personnes': quantity,
    };

    await api.updateEventMenu(eventMenuId, payload);
  }

  @override
  Future<void> addEventMenu({
    required int eventId,
    required int menuId,
    required int dayNumber,
    required MealType meal,
    required int portions,
  }) async {
    await api.addEventMenu({
      'event_id': eventId,
      'menu_id': menuId,
      'day_number': dayNumber,
      'type_repas': meal.name,
      'quantite_personnes': portions,
    });
  }

  @override
  Future<void> deleteEventMenu(int eventMenuId) async {
    await api.deleteEventMenu(eventMenuId);
  }


}
