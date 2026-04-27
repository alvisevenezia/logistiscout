import 'package:flutter/foundation.dart';

@immutable
class IngredientTotal {
  final String name;
  final double quantity;
  final String unit;

  const IngredientTotal({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  IngredientTotal copyWith({
    String? name,
    double? quantity,
    String? unit,
  }) {
    return IngredientTotal(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
  IngredientTotal scale(double factor) {
    return IngredientTotal(
      name: name,
      quantity: quantity * factor,
      unit: unit,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
  };


  factory IngredientTotal.fromJson(Map<String, dynamic> json) {
    return IngredientTotal(
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
    );
  }
}
