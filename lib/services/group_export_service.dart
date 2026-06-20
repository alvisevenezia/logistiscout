import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logistiscout/domain/entities/group.dart';
import 'package:logistiscout/domain/entities/tente.dart';

class GroupExportService {
  GroupExportService._();

  static Future<String?> exportTentsCsv({
    required Group group,
    required List<Tent> tents,
  }) async {
    final fileName = _buildFileName(group);
    final csv = _buildTentsCsv(group, tents);
    final bytes = Uint8List.fromList(utf8.encode(csv));

    if (kIsWeb) {
      throw UnsupportedError('Export CSV non supporte sur le web.');
    }

    return FilePicker.platform.saveFile(
      dialogTitle: 'Choisir ou sauvegarder le CSV',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: bytes,
    );
  }

  static String _buildTentsCsv(Group group, List<Tent> tents) {
    const separator = ';';
    final buffer = StringBuffer()
      ..writeln(
        '\ufeff${_csvRow(const ['group_id', 'group_name', 'group_type', 'tent_id', 'tent_name', 'tent_type', 'tent_places', 'tent_state', 'tent_status_id', 'tent_status_label', 'tent_unit_id', 'tent_unit_name', 'tent_team', 'tent_location', 'tent_embedded_floor', 'tent_comment', 'tent_colors'], separator)}',
      );

    for (final tent in tents) {
      buffer.writeln(
        _csvRow([
          group.id,
          group.name,
          group.type,
          tent.id.toString(),
          tent.nom,
          tent.tentType,
          tent.nbPlaces.toString(),
          tent.displayStatusLabel,
          tent.tentStatusId?.toString() ?? '',
          tent.tentStatusLabel ?? '',
          tent.uniteId?.toString() ?? '',
          tent.assignedUnit,
          tent.team,
          tent.location,
          tent.isFloorEmbedded ? 'true' : 'false',
          tent.comment,
          tent.colors.join('|'),
        ], separator),
      );
    }

    return buffer.toString();
  }

  static String _csvRow(List<String> values, String separator) {
    return values.map((value) => _escapeCsv(value, separator)).join(separator);
  }

  static String _escapeCsv(String value, String separator) {
    final needsQuotes =
        value.contains(separator) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  static Future<String?> exportControlsCsv({
    required Group group,
    required List<Tent> tents,
  }) async {
    final fileName = _buildControlsFileName(group);
    final csv = _buildControlsCsv(group, tents);
    final bytes = Uint8List.fromList(utf8.encode(csv));

    if (kIsWeb) {
      throw UnsupportedError('Export CSV non supporte sur le web.');
    }

    return FilePicker.platform.saveFile(
      dialogTitle: 'Sauvegarder le CSV des controles',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: bytes,
    );
  }

  static String _buildControlsCsv(Group group, List<Tent> tents) {
    const separator = ';';
    final buffer = StringBuffer()
      ..writeln(
        '﻿${_csvRow(const [
          'group_id',
          'group_name',
          'tent_id',
          'tent_name',
          'control_id',
          'control_date',
          'control_comment',
          'control_images',
        ], separator)}',
      );

    for (final tent in tents) {
      for (final control in tent.controlHistory) {
        buffer.writeln(
          _csvRow([
            group.id,
            group.name,
            tent.id.toString(),
            tent.nom,
            control.id?.toString() ?? '',
            control.date.toIso8601String(),
            control.comment,
            control.imageUrls.join('|'),
          ], separator),
        );
      }
    }

    return buffer.toString();
  }

  static String _buildControlsFileName(Group group) {
    final sanitized = group.name
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final baseName = sanitized.isEmpty ? 'group' : sanitized;
    return 'controles_${baseName}_$stamp.csv';
  }

  static String _buildFileName(Group group) {
    final sanitized = group.name
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final baseName = sanitized.isEmpty ? 'group' : sanitized;
    return 'tentes_${baseName}_$stamp.csv';
  }
}
