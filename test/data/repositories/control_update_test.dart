import 'package:flutter_test/flutter_test.dart';
import 'package:logistiscout/data/repositories/controle_repository.dart';
import 'package:logistiscout/domain/entities/controle.dart';
import 'package:logistiscout/domain/entities/status_element_control.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  Control control({List<String> imageUrls = const []}) => Control(
    id: 7,
    tentId: 3,
    userId: 1,
    date: DateTime(2026, 10, 19, 12),
    checklist: const {'Porte': true},
    comment: 'RAS',
    imageUrls: imageUrls,
  );

  group('ControlRepository.updateControl', () {
    late MockApiService api;
    late Map<String, dynamic> sent;

    setUp(() {
      api = MockApiService();
      when(() => api.updateControl(any(), any())).thenAnswer((invocation) async {
        sent = invocation.positionalArguments[1] as Map<String, dynamic>;
      });
    });

    test('envoie la liste des photos a garder', () async {
      await ControlRepository(api: api).updateControl(
        control(imageUrls: ['https://files/b/1.jpg']),
      );

      expect(sent['image_urls'], ['https://files/b/1.jpg']);
    });

    test('envoie une liste vide quand toutes les photos sont retirees', () async {
      await ControlRepository(api: api).updateControl(control());

      expect(sent.containsKey('image_urls'), isTrue);
      expect(sent['image_urls'], isEmpty);
    });
  });

  test('statuts OK/KO relus depuis la checklist', () {
    final statuses = controlItemStatuses({
      'Porte': true,
      'Toile': false,
      'Arceaux': null,
      'Nombre de sardines/piquets': '12',
      'nom_controleur': 'Chef',
    });

    expect(statuses, {
      'Porte': StatusElementControl.ok,
      'Toile': StatusElementControl.ko,
    });
  });
}
