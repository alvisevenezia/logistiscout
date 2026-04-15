import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logistiscout/core/legal_constants.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 24),

            // Avatar et infos de base
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Antoine Warlet',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Groupe SGDF de Saint-Leu-la-Forêt',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Message d’introduction
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "En cas de problème, de suggestion ou de retour à faire sur cette application, "
                "merci de me contacter par l’un des moyens ci dessous.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.science,
                      color: theme.colorScheme.onSecondaryContainer,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rejoindre la version test',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Tu souhaites tester les prochaines fonctionnalités de LogistiScout "
                            "en avant-première ? N’hésite pas à me contacter pour rejoindre "
                            "la version de test de l’application.",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Email
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: const Text('warletanto@cy-tech.fr'),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => _launch('mailto:warletanto@cy-tech.fr'),
                ),
              ),
            ),

            // Groupe SGDF
            Card(
              child: ListTile(
                leading: const Icon(Icons.groups),
                title: const Text('Groupe SGDF'),
                subtitle: const Text('Saint-Leu-la-Forêt'),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.gavel),
                title: const Text('Conditions d\'utilisation'),
                subtitle: const Text('Relire les CGU (version de test)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final username = await LocalStorageService.instance
                      .getUsername();
                  if (!context.mounted) {
                    return;
                  }
                  final encodedUser = Uri.encodeQueryComponent(username ?? '');
                  context.go('/terms?user=$encodedUser&next=/contact');
                },
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2025 Antoine Warlet — LogistiScout',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
