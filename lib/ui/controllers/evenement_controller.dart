import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/data/models/event_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/data/mappers/event_mapper.dart';
import 'dart:developer' as developer;

class EvenementController extends AsyncNotifier<List<Event>> {
  final ApiService api = ApiService();

  @override
  Future<List<Event>> build() async {
    return _loadEvenements();
  }

  Future<List<Event>> _loadEvenements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupeId = prefs.getString('groupeId') ?? '';

      developer.log('[EvenementController] Starting _loadEvenements()');
      developer.log('Retrieved groupeId="$groupeId" from SharedPreferences');

      final data = await api.getEvenements(groupeId);
      developer.log('[EvenementController] API returned ${data.length} events');

      if (data.isNotEmpty) {
        developer.log('First raw event from API: ${data.first}');
      }

      final events = data.map((e) {
        try {
          final dto = EventDto.fromJson(e as Map<String, dynamic>);
          return EventMapper.toDomain(dto);
        } catch (err, st) {
          developer.log('Error converting event: $e', error: err, stackTrace: st);
          rethrow;
        }
      }).toList();

      developer.log('[EvenementController] Successfully loaded ${events.length} events');
      return events;

    } catch (e, st) {
      developer.log('[EvenementController] _loadEvenements() failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => _loadEvenements());
  }

  Future<void> addEvenement(Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final groupeId = prefs.getString('groupeId') ?? '';

    if (groupeId.isEmpty) {
      throw Exception('groupeId introuvable — utilisateur non connecté');
    }

    final dto = EventMapper.toDto(event);
    final json = dto.toJson()..['groupeId'] = groupeId;

    await api.addEvenement(json);
    await reload();
  }

  Future<void> updateEvenement(Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final groupeId = prefs.getString('groupeId') ?? '';

    if (groupeId.isEmpty) {
      throw Exception('groupeId introuvable — utilisateur non connecté');
    }

    final dto = EventMapper.toDto(event);
    final json = dto.toJson()..['groupeId'] = groupeId;

    await api.updateEvenement(event.id, json);
    await reload();
  }

  Future<void> deleteEvenement(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final groupeId = prefs.getString('groupeId') ?? '';
    await api.deleteEvenement(id, groupeId: groupeId);
    await reload();
  }
}

final evenementsProvider =
AsyncNotifierProvider<EvenementController, List<Event>>(
    EvenementController.new);
