class MenuItemDto{
  final int id;
  final int eventId;
  final int recipeId;
  final int dayNumber;
  final String mealType;
  final int portions;

  MenuItemDto({
    required this.id,
    required this.eventId,
    required this.recipeId,
    required this.dayNumber,
    required this.mealType,
    required this.portions,
  });

  factory MenuItemDto.fromJson(Map<String, dynamic> json) {
    return MenuItemDto(
      id: json['id'],
      eventId: json['event_id'],
      recipeId: json['menu_id'],
      dayNumber: json['day_number'],
      mealType: json['type_repas'],
      portions: json['quantite_personnes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'menu_id': recipeId,
      'day_number': dayNumber,
      'type_repas': mealType.toString(),
      'quantite_personnes': portions,
    };
  }

}