import 'package:logistiscout/domain/entities/reservation.dart';
import 'package:logistiscout/domain/entities/controle.dart';

class Tent {
  final int id;
  final String nom;
  final int? uniteId;
  final TentState state;
  final String comment;
  final bool isFloorEmbedded;
  final int nbPlaces;
  final String tentType;
  final String assignedUnit;
  final List<Reservation> agenda;
  final List<Control> controlHistory;
  final List<String> colors;
  final String groupId;

  const Tent({
    required this.id,
    required this.nom,
    required this.uniteId,
    required this.state,
    required this.comment,
    required this.isFloorEmbedded,
    required this.nbPlaces,
    required this.tentType,
    required this.assignedUnit,
    required this.agenda,
    required this.controlHistory,
    required this.colors,
    required this.groupId,
  });

  Tent copyWith({
    int? id,
    String? nom,
    int? uniteId,
    TentState? state,
    String? comment,
    bool? isFloorEmbedded,
    int? nbPlaces,
    String? tentType,
    String? assignedUnit,
    List<Reservation>? agenda,
    List<Control>? controlHistory,
    List<String>? colors,
    String? groupId,
  }) {
    return Tent(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      uniteId: uniteId ?? this.uniteId,
      state: state ?? this.state,
      comment: comment ?? this.comment,
      isFloorEmbedded: isFloorEmbedded ?? this.isFloorEmbedded,
      nbPlaces: nbPlaces ?? this.nbPlaces,
      tentType: tentType ?? this.tentType,
      assignedUnit: assignedUnit ?? this.assignedUnit,
      agenda: agenda ?? this.agenda,
      controlHistory: controlHistory ?? this.controlHistory,
      colors: colors ?? this.colors,
      groupId: groupId ?? this.groupId,
    );
  }
}

enum TentState {
  good(name: "Bon", bgColor: 0xFFE8F5E9, chipColor: 0xFF388E3C),
  repair(name: "À réparer", bgColor: 0xFFFFF8E1, chipColor: 0xFFFFA000),
  broken(name: "HS", bgColor: 0xFFFFEBEE, chipColor: 0xFFD32F2F),
  lost(name: "Perdue", bgColor: 0xFFFAFAFA, chipColor: 0xFF616161);

  const TentState({required this.name, required this.bgColor, required this.chipColor});

  final String name;
  final int bgColor;
  final int chipColor;

}

TentState tentStateFromString(String state) {
  final normalized = state.trim().toLowerCase();

  switch (normalized) {
    case 'bon':
      return TentState.good;

    case 'à réparer':
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
