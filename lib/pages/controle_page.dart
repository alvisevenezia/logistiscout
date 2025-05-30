import 'package:flutter/material.dart';
import 'package:logistiscout/models/database_helper.dart';
import 'package:logistiscout/models/models.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'tente_detail.dart';

class ControlePage extends StatefulWidget {
  const ControlePage({super.key});
  @override
  State<ControlePage> createState() => _ControlePageState();
}

class _ControlePageState extends State<ControlePage> {
  String? qrResult;
  bool showControle = false;
  String? materielType;
  int? materielId;

  void _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRViewExample()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        qrResult = result['code'];
        materielType = result['type'];
        materielId = result['id'];
        showControle = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contrôle du matériel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: showControle && materielType != null && materielId != null
            ? ControleMaterielWidget(type: materielType!, id: materielId!)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _scanQRCode,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scanner un QR code'),
                  ),
                  const SizedBox(height: 24),
                  const Text('Ou sélectionnez un matériel manuellement.'),
                 // Liste des tentes à contrôler (exemple statique, à remplacer par une récupération dynamique)
                  Expanded(
                    child: FutureBuilder<List<Tente>>(
                      future: DatabaseHelper.instance.getAllTentes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('Aucune tente disponible.');
                        }
                        final tentes = snapshot.data!;
                        return ListView.builder(
                          itemCount: tentes.length,
                          itemBuilder: (context, index) {
                            final tente = tentes[index];
                            return ListTile(
                              leading: const Icon(Icons.cabin),
                              title: Text(tente.nom),
                              subtitle: Text('ID: ${tente.id}'),
                              onTap: () {
                                setState(() {
                                  materielType = 'tente';
                                  materielId = tente.id;
                                  showControle = true;
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  bool scanned = false;
  late final MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner le QR code')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (scanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            scanned = true;
            final code = barcodes.first.rawValue;
            final parts = code?.split(':');
            if (parts != null && parts.length == 2) {
              Navigator.pop(context, {
                'type': parts[0],
                'id': int.tryParse(parts[1]),
                'code': code,
              });
            } else {
              Navigator.pop(context, null);
            }
          }
        },
      ),
    );
  }
}

class ControleMaterielWidget extends StatelessWidget {
  final String type;
  final int id;
  const ControleMaterielWidget({super.key, required this.type, required this.id});

  @override
  Widget build(BuildContext context) {
    if (type == 'tente') {
      return FutureBuilder<Tente?>(
        future: DatabaseHelper.instance.getTenteById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Tente introuvable.'));
          }
          return TenteDetailPage(tente: snapshot.data!);
        },
      );
    } else {
      return Center(child: Text('Contrôle du matériel $type ID $id (à implémenter)'));
    }
  }
}
