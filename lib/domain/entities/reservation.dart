class Reservation {
  final DateTime debut;
  final DateTime fin;
  final int eventId;

  Reservation({
    required this.debut,
    required this.fin,
    required this.eventId,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      debut: DateTime.parse(json['debut']),
      fin: DateTime.parse(json['fin']),
      eventId: json['eventId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
      'eventId': eventId,
    };
  }
}