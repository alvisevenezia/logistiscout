import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logistiscout/domain/entities/group_unit.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/tente.dart';

class TentImportResult {
  final List<Tent> tents;
  final List<String> errors;

  const TentImportResult({required this.tents, required this.errors});

  int get created => tents.length;
  int get failed => errors.length;
}

class TentImportService {
  TentImportService._();

  /// Ouvre le file picker, parse le fichier Excel et retourne les données brutes.
  /// Retourne null si l'utilisateur annule.
  static Future<List<Map<String, String>>?> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.first.bytes;
    if (bytes == null) return null;

    return _parseExcel(bytes);
  }

  static List<Map<String, String>> _parseExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) return [];

    final headers = sheet.rows.first
        .map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '')
        .toList();

    final rows = <Map<String, String>>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final map = <String, String>{};
      for (int j = 0; j < headers.length && j < row.length; j++) {
        final header = headers[j];
        final value = row[j]?.value?.toString().trim() ?? '';
        if (header.isNotEmpty) map[header] = value;
      }
      if (map.values.any((v) => v.isNotEmpty)) {
        rows.add(map);
      }
    }
    return rows;
  }

  /// Convertit les lignes brutes en entités Tent, en résolvant les unités et statuts.
  static TentImportResult buildTents({
    required List<Map<String, String>> rows,
    required List<GroupUnit> units,
    required List<TentStatusRef> statuses,
  }) {
    final tents = <Tent>[];
    final errors = <String>[];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rowLabel = 'Ligne ${i + 2}';

      final nom = row['nom'] ?? row['name'] ?? row['tente'] ?? '';
      if (nom.trim().isEmpty) {
        errors.add('$rowLabel : colonne "nom" manquante ou vide.');
        continue;
      }

      final type = _resolveType(row['type'] ?? row['typetente'] ?? '');
      final places = int.tryParse(
            row['places'] ?? row['nbplaces'] ?? row['taille'] ?? '',
          ) ??
          6;
      final comment =
          row['commentaire'] ?? row['comment'] ?? row['remarques'] ?? '';
      final team = row['equipe'] ?? row['team'] ?? '';
      final location = row['localisation'] ?? row['location'] ?? '';
      final embeddedRaw = (row['sol'] ??
              row['sol_integre'] ??
              row['integree'] ??
              'false')
          .toLowerCase();
      final embedded = embeddedRaw == 'true' || embeddedRaw == 'oui';
      final colorStr = row['couleurs'] ?? row['colors'] ?? '';
      final colors = colorStr.isEmpty
          ? <String>[]
          : colorStr
              .split('|')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      final unitLabel =
          row['unite'] ?? row['unit'] ?? row['unite_preferee'] ?? '';
      GroupUnit? resolvedUnit;
      if (unitLabel.trim().isNotEmpty) {
        for (final u in units) {
          if (u.name.trim().toLowerCase() == unitLabel.trim().toLowerCase()) {
            resolvedUnit = u;
            break;
          }
        }
        if (resolvedUnit == null) {
          errors.add(
            '$rowLabel : unité "$unitLabel" introuvable — tente créée sans unité.',
          );
        }
      }

      final statusLabel =
          row['statut'] ?? row['etat'] ?? row['status'] ?? '';
      TentStatusRef? resolvedStatus;
      if (statusLabel.trim().isNotEmpty) {
        for (final s in statuses) {
          if (s.name.trim().toLowerCase() ==
              statusLabel.trim().toLowerCase()) {
            resolvedStatus = s;
            break;
          }
        }
        if (resolvedStatus == null) {
          errors.add(
            '$rowLabel : statut "$statusLabel" introuvable — statut par défaut appliqué.',
          );
        }
      }
      resolvedStatus ??= statuses.isNotEmpty ? statuses.first : null;

      tents.add(Tent(
        id: -1,
        nom: nom.trim(),
        uniteId: resolvedUnit != null ? int.tryParse(resolvedUnit.id) : null,
        state: tentStateFromString(resolvedStatus?.name ?? 'Bon'),
        tentStatusId: resolvedStatus?.id,
        tentStatusLabel: resolvedStatus?.name,
        tentStatusColor: resolvedStatus?.color,
        comment: comment,
        isFloorEmbedded: embedded,
        nbPlaces: places,
        tentType: type,
        assignedUnit: resolvedUnit?.name ?? '',
        agenda: const [],
        controlHistory: const [],
        colors: colors,
        groupId: '0',
        team: team,
        location: location,
      ));
    }

    return TentImportResult(tents: tents, errors: errors);
  }

  static String _resolveType(String raw) {
    const valid = ['Canadienne', 'Tipi', 'Marabout', 'Autre'];
    final normalized = raw.trim().toLowerCase();
    for (final v in valid) {
      if (v.toLowerCase() == normalized) return v;
    }
    return 'Canadienne';
  }
}
