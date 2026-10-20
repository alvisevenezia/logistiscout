import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/domain/entities/event.dart';
import 'package:logistiscout/domain/entities/home_tile.dart';
import 'package:logistiscout/domain/entities/item.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/tente.dart';
import 'package:logistiscout/data/models/login_notice_dto.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/services/token_store.dart';
import 'package:logistiscout/ui/controllers/home_controller.dart';
import 'package:logistiscout/ui/controllers/items_controller.dart';
import 'package:logistiscout/ui/widgets/common/event_card.dart';
import 'package:logistiscout/ui/widgets/common/tent_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logistiscout/ui/widgets/home/home_stat_card.dart';
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
    if (!mounted) {
      return;
    }

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
    final statuses =
        ref.watch(accountControllerProvider).valueOrNull?.tentStatuses ??
        const <TentStatusRef>[];
    final tentesToRepair = tentsNeedingRepair(state.tentes, statuses);
    // Matériel et signalements : 0 tant que l'API ne les fournit pas.
    final items = ref.watch(itemsProvider).valueOrNull ?? const <Item>[];
    final openIssues = ref.watch(openIssuesProvider).valueOrNull ?? const [];
    final overview = HomeOverviewData(
      tents: state.tentes,
      statuses: statuses,
      upcomingEventsCount: prochainsEvts.length,
      usedTentsCount: tentesUtilisees.length,
      itemsCount: items.length,
      itemsToRepairCount: items.where((i) => i.usage != ItemUsage.ok).length,
      openIssuesCount: openIssues.length,
    );
    final tiles =
        ref.watch(homeTilesControllerProvider).valueOrNull ??
        HomeTile.defaults;
    final overviewCards = [
      for (final tile in tiles)
        if (tile.visible) homeStatCardFor(tile, overview),
    ];

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
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Se déconnecter ?'),
                  content: const Text(
                    'Voulez-vous vraiment vous déconnecter de votre compte ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await controller.logout(ref);
                if (context.mounted) {
                  context.go('/login');
                }
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
            totalTentes: state.tentes.length,
            prochainsEvts: prochainsEvts,
            tentesUtilisees: tentesUtilisees,
            tentesToRepair: tentesToRepair,
            overviewCards: overviewCards,
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

  Future<void> _launchActionUrl(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(await canLaunchUrl(uri))) {
      developer.log('[HomePage] cannot launch notice action url: $url');
      messenger?.showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir ce lien.')),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          if (notice.actionUrl != null && notice.actionUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => _launchActionUrl(context, notice.actionUrl!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(
                  notice.actionLabel != null && notice.actionLabel!.isNotEmpty
                      ? notice.actionLabel!
                      : 'Ouvrir le lien',
                ),
              ),
            ),
          ] else if (notice.actionLabel != null &&
              notice.actionLabel!.isNotEmpty) ...[
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

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.isLoading,
    required this.error,
    required this.isOffline,
    required this.hasData,
    required this.totalTentes,
    required this.prochainsEvts,
    required this.tentesUtilisees,
    required this.tentesToRepair,
    required this.overviewCards,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final bool isOffline;
  final bool hasData;
  final int totalTentes;

  final List<Event> prochainsEvts;
  final List<Tent> tentesUtilisees;
  final List<Tent> tentesToRepair;
  final List<HomeStatCardData> overviewCards;
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
                  _HomeStatsStrip(
                    cards: overviewCards,
                    onCustomize: () => context.push('/home-tiles'),
                  ),
                  const SizedBox(height: 20),
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

class _HomeStatsStrip extends StatelessWidget {
  const _HomeStatsStrip({required this.cards, required this.onCustomize});

  final List<HomeStatCardData> cards;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Aperçu',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: onCustomize,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Personnaliser'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 520;
            if (isWide) {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.7,
                children: cards
                    .map((data) => HomeStatCard(data: data))
                    .toList(),
              );
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map(
                    (data) => SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: HomeStatCard(data: data),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

