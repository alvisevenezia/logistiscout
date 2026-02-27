import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';

import 'dart:developer' as developer;

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountControllerProvider);
    final controller = ref.read(accountControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("Mon compte")),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Erreur: $e")),
        data: (group) {

          developer.log("group: ${group.name}, email: ${group.email}");

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text("Nom du groupe : ${group.name}"),
              Text("Email : ${group.email}"),
              const SizedBox(height: 20),

              // Exemple : bouton refresh
              ElevatedButton(
                onPressed: () => controller.build(),
                child: const Text("Recharger"),
              ),
            ],
          );
        },
      ),
    );
  }
}