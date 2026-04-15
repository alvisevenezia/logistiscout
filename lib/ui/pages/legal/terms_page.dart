import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logistiscout/services/api_service.dart';
import 'package:logistiscout/services/local_storage_service.dart';
import 'package:logistiscout/services/token_store.dart';
import 'package:logistiscout/ui/pages/legal/legal_texts.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({
    super.key,
    required this.termsVersion,
    required this.userIdentity,
    required this.nextRoute,
  });

  final String termsVersion;
  final String userIdentity;
  final String nextRoute;

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool _accepted = false;
  bool _saving = false;
  String? _error;

  Future<void> _confirmAcceptance() async {
    if (!_accepted || _saving) {
      return;
    }
    setState(() => _saving = true);

    try {
      await ApiService().acceptTermsOnServer(widget.termsVersion);
      await LocalStorageService.instance.acceptTerms(
        userIdentity: widget.userIdentity,
        termsVersion: widget.termsVersion,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = 'Impossible d\'enregistrer votre acceptation sur le serveur.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur reseau ou serveur. Reessayez.')),
      );
      return;
    }

    if (!mounted) {
      return;
    }
    context.go(widget.nextRoute);
  }

  Future<void> _decline() async {
    await TokenStore.instance.clear();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      children: const [
                        Text(
                          'Mentions legales - Version de test',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Derniere mise a jour:  $kLegalLastUpdate',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Conditions Generales d\'Utilisation (CGU)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(kTermsDraftText),
                        SizedBox(height: 20),
                        Text(
                          'Politique de confidentialite (brouillon)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(kPrivacyDraftText),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              CheckboxListTile(
                value: _accepted,
                onChanged: (value) =>
                    setState(() => _accepted = value ?? false),
                title: const Text(
                  'Je reconnais avoir lu et j\'accepte les CGU et la politique de confidentialite (version de test).',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _decline,
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (!_accepted || _saving)
                          ? null
                          : _confirmAcceptance,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Accepter et continuer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
