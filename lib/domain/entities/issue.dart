enum IssueTargetKind {
  tent('tent'),
  item('item');

  const IssueTargetKind(this.jsonValue);

  final String jsonValue;

  static IssueTargetKind fromJson(Object? value) {
    return value == 'item' ? IssueTargetKind.item : IssueTargetKind.tent;
  }
}

enum IssueState {
  open('open'),
  resolved('resolved'),
  dismissed('dismissed');

  const IssueState(this.jsonValue);

  final String jsonValue;

  static IssueState fromJson(Object? value) {
    return IssueState.values.firstWhere(
      (s) => s.jsonValue == value,
      orElse: () => IssueState.open,
    );
  }
}

/// Ce sur quoi porte un signalement : une tente ou un matériel.
class IssueTarget {
  final IssueTargetKind kind;
  final int id;

  const IssueTarget(this.kind, this.id);

  const IssueTarget.tent(this.id) : kind = IssueTargetKind.tent;
  const IssueTarget.item(this.id) : kind = IssueTargetKind.item;

  @override
  bool operator ==(Object other) =>
      other is IssueTarget && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

/// Signalement d'un problème, sans contrôle complet.
class Issue {
  final int id;
  final IssueTarget target;
  final String? targetName;
  final String description;
  final int quantity;

  /// L'objet reste utilisable (à réparer) ou non (hors service).
  final bool usable;
  final String? reporterName;
  final String? photoUrl;
  final IssueState state;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const Issue({
    required this.id,
    required this.target,
    this.targetName,
    required this.description,
    this.quantity = 1,
    this.usable = true,
    this.reporterName,
    this.photoUrl,
    this.state = IssueState.open,
    required this.createdAt,
    this.resolvedAt,
  });

  bool get isOpen => state == IssueState.open;

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: (json['id'] as num?)?.toInt() ?? 0,
      target: IssueTarget(
        IssueTargetKind.fromJson(json['targetKind']),
        (json['targetId'] as num?)?.toInt() ?? 0,
      ),
      targetName: json['targetName'] as String?,
      description: json['description']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      usable: json['usable'] != false,
      reporterName: json['reporterName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      state: IssueState.fromJson(json['state']),
      createdAt: _parseUtc(json['createdAt']) ?? DateTime.now(),
      resolvedAt: _parseUtc(json['resolvedAt']),
    );
  }
}

/// L'API renvoie des dates UTC sans fuseau : on les relit en UTC puis en local.
DateTime? _parseUtc(Object? value) {
  if (value == null) return null;
  final raw = value.toString();
  final hasZone = raw.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(raw);
  return DateTime.tryParse(hasZone ? raw : '${raw}Z')?.toLocal();
}
