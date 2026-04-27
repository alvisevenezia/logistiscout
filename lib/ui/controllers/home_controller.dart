// presentation/controllers/accueil_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/data/repositories/event_repository_impl.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/data/repositories/tente_repository_impl.dart';
import 'package:logistiscout/services/app_exception.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/services/token_store.dart';
import 'package:logistiscout/ui/controllers/evenement_controller.dart';
import 'package:logistiscout/ui/controllers/tentes_controller.dart';
import 'package:logistiscout/core/di.dart';

class HomeState {
  final List<Event> evenements;
  final List<Tent> tentes;
  final bool isLoading;
  final String? error;
  final bool isOffline;

  const HomeState({
    this.evenements = const [],
    this.tentes = const [],
    this.isLoading = false,
    this.error,
    this.isOffline = false,
  });

  HomeState copyWith({
    List<Event>? evenements,
    List<Tent>? tentes,
    bool? isLoading,
    String? error,
    bool? isOffline,
  }) {
    return HomeState(
      evenements: evenements ?? this.evenements,
      tentes: tentes ?? this.tentes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  final EventRepositoryImpl evenementRepo;
  final TentRepositoryImpl tenteRepo;
  final LocalStorageService storage;

  HomeController(this.evenementRepo, this.tenteRepo, this.storage)
    : super(const HomeState());

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null, isOffline: false);

    try {
      final evts = await evenementRepo.getAllEvents();
      final tts = await tenteRepo.getTentList();
      state = state.copyWith(evenements: evts, tentes: tts, isLoading: false);
    } catch (e) {
      final offline = (e is AppException) && e.message.contains('connexion');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isOffline: offline,
      );
    }
  }

  Future<void> logout(WidgetRef ref) async {
    await LocalStorageService.instance.clearAll();
    await TokenStore.instance.clear();

    if (mounted) {
      state = const HomeState();
    }

    ref.invalidate(evenementsProvider);
    ref.invalidate(tentesProvider);
    ref.invalidate(accountControllerProvider);
    ref.invalidate(accueilControllerProvider);
  }

  Future<void> refresh(WidgetRef ref) async {
    // re-run the same fetch logic you do on init
    await loadData();
  }
}

final accueilControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
      final c = HomeController(
        EventRepositoryImpl(ApiService()),
        TentRepositoryImpl(ApiService()),
        LocalStorageService.instance,
      );
      Future.microtask(c.loadData);
      return c;
    });
