import 'package:logistiscout/domain/entities/reservation.dart';
import 'package:logistiscout/domain/entities/controle.dart';

const _uniteIdNotProvided = Object();

class Tent {
  final int id;
  final String nom;
  final int? uniteId;
  final TentState state;
  final int? tentStatusId;
  final String? tentStatusLabel;
  final int? tentStatusColor;
  final String comment;
  final bool isFloorEmbedded;
  final int nbPlaces;
  final String tentType;
  final String assignedUnit;
  final List<Reservation> agenda;
  final List<Control> controlHistory;
  final List<String> colors;
  final String groupId;
  final String team;
  final String location;

  const Tent({
    required this.id,
    required this.nom,
    required this.uniteId,
    required this.state,
    required this.tentStatusId,
    required this.tentStatusLabel,
    required this.tentStatusColor,
    required this.comment,
    required this.isFloorEmbedded,
    required this.nbPlaces,
    required this.tentType,
    required this.assignedUnit,
    required this.agenda,
    required this.controlHistory,
    required this.colors,
    required this.groupId,
    required this.team,
    required this.location,
  });

  Tent copyWith({
    int? id,
    String? nom,
    Object? uniteId = _uniteIdNotProvided,
    TentState? state,
    Object? tentStatusId = _uniteIdNotProvided,
    String? tentStatusLabel,
    Object? tentStatusColor = _uniteIdNotProvided,
    String? comment,
    bool? isFloorEmbedded,
    int? nbPlaces,
    String? tentType,
    String? assignedUnit,
    List<Reservation>? agenda,
    List<Control>? controlHistory,
    List<String>? colors,
    String? groupId,
    String? team,
    String? location,
  }) {
    final nextUniteId = identical(uniteId, _uniteIdNotProvided)
        ? this.uniteId
        : uniteId as int?;
    final nextStatusId = identical(tentStatusId, _uniteIdNotProvided)
        ? this.tentStatusId
        : tentStatusId as int?;
    final nextStatusColor = identical(tentStatusColor, _uniteIdNotProvided)
        ? this.tentStatusColor
        : tentStatusColor as int?;

    return Tent(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      uniteId: nextUniteId,
      state: state ?? this.state,
      tentStatusId: nextStatusId,
      tentStatusLabel: tentStatusLabel ?? this.tentStatusLabel,
      tentStatusColor: nextStatusColor,
      comment: comment ?? this.comment,
      isFloorEmbedded: isFloorEmbedded ?? this.isFloorEmbedded,
      nbPlaces: nbPlaces ?? this.nbPlaces,
      tentType: tentType ?? this.tentType,
      assignedUnit: assignedUnit ?? this.assignedUnit,
      agenda: agenda ?? this.agenda,
      controlHistory: controlHistory ?? this.controlHistory,
      colors: colors ?? this.colors,
      groupId: groupId ?? this.groupId,
      team: team ?? this.team,
      location: location ?? this.location,
    );
  }

  String get displayStatusLabel => tentStatusLabel ?? tentStateToString(state);

  int get displayStatusColor {
    if (tentStatusColor != null) {
      return tentStatusColor!;
    }
    return state.chipColor;
  }

  ColorPair get displayStatusPalette =>
      ColorPair(label: displayStatusLabel, color: displayStatusColor);
}

class ColorPair {
  final String label;
  final int color;

  const ColorPair({required this.label, required this.color});
}

enum TentState {
  good(name: "Bon", bgColor: 0xFFE8F5E9, chipColor: 0xFF388E3C),
  repair(name: "À réparer", bgColor: 0xFFFFF8E1, chipColor: 0xFFFFA000),
  broken(name: "HS", bgColor: 0xFFFFEBEE, chipColor: 0xFFD32F2F),
  lost(name: "Perdue", bgColor: 0xFFFAFAFA, chipColor: 0xFF616161);

  const TentState({
    required this.name,
    required this.bgColor,
    required this.chipColor,
  });

  final String name;
  final int bgColor;
  final int chipColor;
}

TentState tentStateFromString(String state) {
  final normalized = state.trim().toLowerCase();

  switch (normalized) {
    case 'bon':
    case 'ok':
    case 'good':
      return TentState.good;

    case 'à réparer':
    case 'a reparer':
    case 'repair':
      return TentState.repair;

    case 'hs':
      return TentState.broken;

    case 'perdue':
      return TentState.lost;

    default:
      return TentState.good;
  }
}

String tentStateToString(TentState e) {
  switch (e) {
    case TentState.good:
      return 'Bon';
    case TentState.repair:
      return 'À réparer';
    case TentState.broken:
      return 'HS';
    case TentState.lost:
      return 'Perdue';
  }
}
