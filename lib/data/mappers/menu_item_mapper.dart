import 'package:logistiscout/data/models/menu_item_dto.dart';
import 'package:logistiscout/domain/entities/menu.dart';

MenuItemDto menuItemToDto(MenuItem entity) {
  return MenuItemDto(
    id: entity.id,
    eventId: entity.eventId,
    recipeId: entity.recipeId,
    dayNumber: entity.dayNumber,
    mealType: entity.mealType.toString(),
    portions: entity.portions
  );
}

MenuItem menuItemDtoToDomain(MenuItemDto dto) {
  return MenuItem(
    id: dto.id,
    eventId: dto.eventId,
    recipeId: dto.recipeId,
    dayNumber: dto.dayNumber,
    mealType: MealType.values.firstWhere((e) => e.name == dto.mealType),
    portions: dto.portions
  );
}
