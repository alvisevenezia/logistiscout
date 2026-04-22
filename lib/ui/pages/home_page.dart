import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/data/models/login_notice_dto.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/services/token_store.dart';
import 'package:logistiscout/ui/controllers/home_controller.dart';
import 'package:logistiscout/ui/widgets/common/event_card.dart';
import 'package:logistiscout/ui/widgets/common/tent_card.dart';
import 'dart:developer' as developer;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int tapCount = 0;
  DateTime? firstTapTime;
  bool _migrationPopupShown = false;
  bool _noticesChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoginNotices();
    });
  }

  void handleTripleTap() {
    final now = DateTime.now();

    // Si plus d'1 sec → reset
    if (firstTapTime == null ||
        now.difference(firstTapTime!) > const Duration(seconds: 1)) {
      tapCount = 0;
      firstTapTime = now;
    }

    tapCount++;

    if (tapCount == 1) {
      firstTapTime = now;
    }

    if (tapCount == 3 &&
        now.difference(firstTapTime!) <= const Duration(seconds: 1)) {
      final confirm = showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Réinitialiser ?'),
          content: const Text(
            'UNIQUEMENT POUR DU DEBUG \n\nCela va effacer vos données locales (nom du contrôleur, groupe, etc.). Continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        LocalStorageService.instance.clearAll();
        TokenStore.instance.clear();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Préférences locales effacées ✅')),
          );
        }
      }

      tapCount = 0;
    }
  }

  Future<void> _showLoginNotices() async {
    if (_noticesChecked || !mounted) {
      return;
    }
    _noticesChecked = true;

    try {
      final notices = await ref.read(apiServiceProvider).getActiveNotices();
      if (notices.isEmpty || !mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Informations de connexion'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final notice in notices) ...[
                      _LoginNoticeCard(notice: notice),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    await ref
                        .read(apiServiceProvider)
                        .acknowledgeNotices(
                          notices.map((notice) => notice.id).toList(),
                        );
                  } catch (e, st) {
                    developer.log(
                      '[HomePage] failed to acknowledge login notices',
                      error: e,
                      stackTrace: st,
                    );
                  }
                },
                child: const Text('J\'ai compris'),
              ),
            ],
          );
        },
      );
    } catch (e, st) {
      developer.log(
        '[HomePage] failed to load login notices',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(accountControllerProvider, (previous, next) {
      final group = next.valueOrNull;
      if (_migrationPopupShown || group == null) {
        return;
      }
      if (!group.unitsMigrationPerformed) {
        return;
      }

      _migrationPopupShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Nouvelles fonctionnalites unites'),
            content: const Text(
              'Votre compte utilisait un ancien format. '
              'Nous avons migre automatiquement vos donnees d\'unite pour '
              'activer les nouvelles fonctionnalites.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    });

    final state = ref.watch(accueilControllerProvider);
    final controller = ref.read(accueilControllerProvider.notifier);

    // Compute lists only when data is present
    final now = DateTime.now();
    final evtsAVenir = [...state.evenements]
      ..sort((a, b) => a.date.compareTo(b.date));
    final prochainsEvts = evtsAVenir
        .where((e) => e.dateFin.isAfter(now))
        .take(3)
        .toList();

    final tentesUtiliseesIds = prochainsEvts
        .expand((e) => e.associatedTents)
        .toSet();
    final tentesUtilisees = state.tentes
        .where((t) => tentesUtiliseesIds.contains(t.id))
        .toList();
    final tentesToRepair = state.tentes
        .where((t) => _isNonNominalStatus(t.displayStatusLabel))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: () => handleTripleTap(),
          child: const Text(
            'Accueil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        bottom: state.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Configuration',
            onPressed: () => context.push('/account'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await controller.logout(ref);
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),

      // ✅ Body always exists; we switch content inside it
      body: Stack(
        children: [
          // Main content area
          _HomeBody(
            isLoading: state.isLoading,
            error: state.error,
            isOffline: state.isOffline,
            hasData: state.evenements.isNotEmpty || state.tentes.isNotEmpty,
            prochainsEvts: prochainsEvts,
            tentesUtilisees: tentesUtilisees,
            tentesToRepair: tentesToRepair,
            onRetry: () =>
                controller.refresh(ref), // add this method in controller
          ),

          // Optional: loading overlay (keeps content visible underneath)
          if (state.isLoading)
            const Positioned.fill(
              child: IgnorePointer(
                ignoring: true, // user can still scroll/click logout in AppBar
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x33FFFFFF)),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoginNoticeCard extends StatelessWidget {
  final LoginNoticeDto notice;

  const _LoginNoticeCard({required this.notice});

  Color _levelColor() {
    switch (notice.level.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      case 'warning':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _levelIcon() {
    switch (notice.level.toLowerCase()) {
      case 'critical':
        return Icons.report;
      case 'maintenance':
        return Icons.build;
      case 'warning':
        return Icons.warning_amber;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '';
    }
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month ${hour}h$minute';
  }

  @override
  Widget build(BuildContext context) {
    final color = _levelColor();
    final timeLabel = notice.startAt != null || notice.endAt != null
        ? [
            if (notice.startAt != null)
              'Début: ${_formatDateTime(notice.startAt)}',
            if (notice.endAt != null) 'Fin: ${_formatDateTime(notice.endAt)}',
          ].join(' • ')
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_levelIcon(), color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notice.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(notice.message),
          if (timeLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              timeLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
          if (notice.actionLabel != null && notice.actionLabel!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              notice.actionLabel!,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

bool _isNonNominalStatus(String label) {
  final normalized = label.trim().toLowerCase();
  return normalized.isNotEmpty && normalized != 'bon' && normalized != 'ok';
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.isLoading,
    required this.error,
    required this.isOffline,
    required this.hasData,
    required this.prochainsEvts,
    required this.tentesUtilisees,
    required this.tentesToRepair,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final bool isOffline;
  final bool hasData;

  final List<Event> prochainsEvts;
  final List<Tent> tentesUtilisees;
  final List<Tent> tentesToRepair;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // If there's an error AND no data at all => full error UI
    if (error != null && !hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Erreur: $error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise: show content, and if offline/error => show banner on top
    return Column(
      children: [
        if (isOffline)
          MaterialBanner(
            content: const Text(
              'Hors connexion — affichage des dernières données',
            ),
            actions: [
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          )
        else if (error != null)
          MaterialBanner(
            content: Text('Erreur: $error'),
            actions: [
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => onRetry(), // controller.refresh(ref)
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // allows pull even if content is short
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prochains événements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (prochainsEvts.isEmpty)
                    const Text('Aucun événement à venir.')
                  else
                    ...prochainsEvts.map(
                      (event) =>
                          EventCard(event: event, onOpen: () {}, detail: false),
                    ),

                  const SizedBox(height: 24),
                  Text(
                    'Tentes à réparer',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (tentesToRepair.isEmpty)
                    const Text(
                      'Aucune tente réservée pour les prochains événements.',
                    )
                  else
                    ...tentesToRepair.map(
                      (t) => TentCard(tent: t, detail: false),
                    ),

                  const SizedBox(height: 24),
                  Text(
                    'Tentes utilisées prochainement',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (tentesUtilisees.isEmpty)
                    const Text(
                      'Aucune tente réservée pour les prochains événements.',
                    )
                  else
                    ...tentesUtilisees.map(
                      (t) => TentCard(tent: t, detail: false),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
