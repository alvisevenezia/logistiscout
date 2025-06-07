import 'package:flutter/material.dart';
import 'package:logistiscout/models/api_service.dart';
import 'package:logistiscout/models/models.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner le QR code')),
      body: MobileScanner(
        controller: MobileScannerController(),
        onDetect: (capture) async {
          if (showControle) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            showControle = true;
            final code = barcodes.first.rawValue;
            dynamic result;
            try {
              result = code != null ? jsonDecode(code) : null;
            } catch (_) {
              result = null;
            }
            //print('QR code parsé :');
            //print(result);
            if (result is Map && result.containsKey('type') && result.containsKey('id') && result.containsKey('groupeId')) {
              final prefs = await SharedPreferences.getInstance();
              final userGroupeId = prefs.getString('groupeId') ?? '';
              if (result['groupeId'].toString() != userGroupeId) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vous n'avez pas le droit de modifier cette tente (groupe différent).")),
                  );
                }
                showControle = false;
                return;
              }
              Navigator.pop(context, {
                'type': result['type'],
                'id': result['id'],
                'groupeId': result['groupeId'],
                'code': code,
              });
            } else {
              // fallback: ancien format type:id
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
          }
        },
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
        onDetect: (capture) async {
          if (scanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            scanned = true;
            final code = barcodes.first.rawValue;
            dynamic result;
            try {
              result = code != null ? jsonDecode(code) : null;
            } catch (_) {
              result = null;
            }
            //print('QR code parsé :');
            //print(result);
            if (result is Map && result.containsKey('type') && result.containsKey('id') && result.containsKey('groupeId')) {
              final prefs = await SharedPreferences.getInstance();
              final userGroupeId = prefs.getString('groupeId') ?? '';
              if (result['groupeId'].toString() != userGroupeId) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vous n'avez pas le droit de modifier cette tente (groupe différent).")),
                  );
                }
                scanned = false;
                return;
              }
              Navigator.pop(context, {
                'type': result['type'],
                'id': result['id'],
                'groupeId': result['groupeId'],
                'code': code,
              });
            } else {
              // fallback: ancien format type:id
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
        future: (() async {
          final prefs = await SharedPreferences.getInstance();
          final groupeId = prefs.getString('groupeId') ?? '';
          final t = await ApiService.getTente(id, groupeId: groupeId);
          return Tente.fromJson(t);
        })(),
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
