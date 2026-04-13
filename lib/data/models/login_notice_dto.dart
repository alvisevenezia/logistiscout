class LoginNoticeDto {
  final int id;
  final String title;
  final String message;
  final String level;
  final int? targetGroupId;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool requiresAck;
  final int displayOrder;
  final String? actionLabel;
  final String? actionUrl;

  const LoginNoticeDto({
    required this.id,
    required this.title,
    required this.message,
    required this.level,
    required this.targetGroupId,
    required this.startAt,
    required this.endAt,
    required this.requiresAck,
    required this.displayOrder,
    required this.actionLabel,
    required this.actionUrl,
  });

  factory LoginNoticeDto.fromJson(Map<String, dynamic> json) {
    return LoginNoticeDto(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      level: (json['level'] as String?) ?? 'info',
      targetGroupId: json['targetGroupId'] as int?,
      startAt: json['startAt'] == null
          ? null
          : DateTime.parse(json['startAt'] as String),
      endAt: json['endAt'] == null
          ? null
          : DateTime.parse(json['endAt'] as String),
      requiresAck: json['requiresAck'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
      actionLabel: json['actionLabel'] as String?,
      actionUrl: json['actionUrl'] as String?,
    );
  }
}
