import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistiscout/core/di.dart';
import 'package:logistiscout/data/mappers/receipe_mapper.dart';
import 'package:logistiscout/data/models/receipe_dto.dart';
import 'package:logistiscout/domain/entities/recipe.dart';

final recipeProvider = FutureProvider.family.autoDispose<Recipe, int>((ref, int menuId) async {
  final data = await ref.read(apiServiceProvider).getReceipe(menuId); // api vient de core/di.dart
  return  recipeDtoToRecipe(RecipeDto.fromJson(data));
});