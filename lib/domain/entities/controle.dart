class Control {
  final int? id;
  final int tentId;
  final int userId;
  final DateTime date;
  final Map<String, dynamic> checklist;
  final String comment;
  final String? imageUrl;
  final List<String> imageUrls;

  const Control({
    this.id,
    required this.tentId,
    required this.userId,
    required this.date,
    required this.checklist,
    required this.comment,
    this.imageUrl,
    this.imageUrls = const [],
  });

  Control copyWith({
    int? id,
    int? tentId,
    int? userId,
    DateTime? date,
    Map<String, dynamic>? checklist,
    String? comment,
    String? imageUrl,
    List<String>? imageUrls,
  }) {
    return Control(
      id: id ?? this.id,
      tentId: tentId ?? this.tentId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      checklist: checklist ?? this.checklist,
      comment: comment ?? this.comment,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  @override
  String toString() {
    return 'Controle(id: $id, tenteId: $tentId, userId: $userId, date: $date, remarques: $comment)';
  }

  Map<String, dynamic> toJson() {
    return {
      'tentId': tentId,
      'userId': userId,
      'date': date.toString(),
      'checklist': checklist,
      'comment': comment,
      if (imageUrl != null) 'image_url': imageUrl,
      if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
    };
  }

  factory Control.fromJson(Map<String, dynamic> json) {
    final checklist = Map<String, dynamic>.from(json['checklist'] ?? {});
    final rawImageUrls = json['image_urls'] ?? checklist['photo_urls'];
    final parsedImageUrls = rawImageUrls is List
        ? rawImageUrls.map((e) => e.toString()).toList()
        : <String>[];
    final imageUrl = json['image_url'] ?? json['imageUrl'];
    return Control(
      id: json['id'],
      tentId: json['tentId'] ?? json['tenteId'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      checklist: checklist,
      comment: json['comment'] ?? json['remarques'] ?? '',
      imageUrl:
          imageUrl ??
          (parsedImageUrls.isNotEmpty ? parsedImageUrls.first : null),
      imageUrls: parsedImageUrls,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Control &&
        other.id == id &&
        other.tentId == tentId &&
        other.userId == userId &&
        other.date == date &&
        other.comment == comment &&
        other.imageUrl == imageUrl &&
        _listEquals(other.imageUrls, imageUrls);
  }

  @override
  int get hashCode =>
      id.hashCode ^
      tentId.hashCode ^
      userId.hashCode ^
      date.hashCode ^
      comment.hashCode ^
      imageUrl.hashCode ^
      imageUrls.hashCode;

  bool _listEquals(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}
