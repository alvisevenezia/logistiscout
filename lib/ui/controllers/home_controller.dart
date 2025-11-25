// presentation/controllers/accueil_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/data/repositories/event_repository_impl.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/data/repositories/tente_repository_impl.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/ui/controllers/evenement_controller.dart';
import 'package:logistiscout/ui/controllers/tentes_controller.dart';

class HomeState {
  final List<Event> evenements;
  final List<Tent> tentes;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.evenements = const [],
    this.tentes = const [],
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<Event>? evenements,
    List<Tent>? tentes,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      evenements: evenements ?? this.evenements,
      tentes: tentes ?? this.tentes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  final EventRepositoryImpl evenementRepo;
  final TenteRepositoryImpl tenteRepo;
  final LocalStorageService storage;

  HomeController(this.evenementRepo, this.tenteRepo, this.storage)
      : super(const HomeState());

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final evts = await evenementRepo.getAllEvents();
      final tts = await tenteRepo.getTentList();
      state = state.copyWith(evenements: evts, tentes: tts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout(WidgetRef ref) async {
    // 1️⃣ Supprimer les données locales
    await LocalStorageService.instance.clearAll();

    // 2️⃣ Réinitialiser ton propre état
    if (mounted) {
      state = const HomeState(); // ✅ et pas AsyncData
    }

    // 3️⃣ Invalider les autres providers pour vider le cache
    ref.invalidate(evenementsProvider);
    ref.invalidate(tentesProvider);

    // ⚠️ Ne pas t’invalider toi-même ici, sinon "after dispose" error
  }
}


final accueilControllerProvider =
StateNotifierProvider<HomeController, HomeState>((ref) {
  final c = HomeController(
    EventRepositoryImpl(ApiService()),
    TenteRepositoryImpl(ApiService()),
    LocalStorageService.instance,
  );
  // Démarrage immédiat du chargement (asynchrone)
  Future.microtask(c.loadData);
  return c;
});
