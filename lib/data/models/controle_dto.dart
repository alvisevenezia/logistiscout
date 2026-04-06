// lib/data/modals/controle_dto.dart
class ControlDto {
  final int? id;
  final int tentId;
  final int userId;
  final String date; // stored as ISO 8601 string
  final Map<String, dynamic> checklist;
  final String comments;
  final String? imageUrl;
  final List<String> imageUrls;

  ControlDto({
    this.id,
    required this.tentId,
    required this.userId,
    required this.date,
    required this.checklist,
    required this.comments,
    this.imageUrl,
    this.imageUrls = const [],
  });

  factory ControlDto.fromJson(Map<String, dynamic> json) => ControlDto(
    id: json['id'],
    tentId: json['tenteId'],
    userId: json['userId'],
    date: json['date'],
    checklist: Map<String, dynamic>.from(json['checklist'] ?? {}),
    comments: json['remarques'] ?? '',
    imageUrl: json['image_url'],
    imageUrls: (json['image_urls'] is List)
        ? (json['image_urls'] as List).map((e) => e.toString()).toList()
        : (Map<String, dynamic>.from(json['checklist'] ?? {})['photo_urls']
              is List)
        ? (Map<String, dynamic>.from(json['checklist'] ?? {})['photo_urls']
                  as List)
              .map((e) => e.toString())
              .toList()
        : const [],
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'tenteId': tentId,
    'userId': userId,
    'date': date,
    'checklist': checklist,
    'remarques': comments,
    if (imageUrl != null) 'image_url': imageUrl,
    if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
  };
}
