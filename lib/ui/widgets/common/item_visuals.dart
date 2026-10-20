import 'package:flutter/material.dart';
import 'package:logistiscout/domain/entities/item.dart';
import 'package:logistiscout/domain/entities/tent_status.dart';
import 'package:logistiscout/domain/entities/tente.dart';

/// Icônes Material nommées par le catalogue de l'API.
const _itemIcons = <String, IconData>{
  'holiday_village': Icons.holiday_village,
  'change_history': Icons.change_history,
  'roofing': Icons.roofing,
  'inventory_2': Icons.inventory_2,
  'local_fire_department': Icons.local_fire_department,
  'propane': Icons.propane,
  'soup_kitchen': Icons.soup_kitchen,
  'skillet': Icons.outdoor_grill,
  'flatware': Icons.flatware,
  'kitchen': Icons.kitchen,
  'water_drop': Icons.water_drop,
  'water': Icons.water,
  'carpenter': Icons.carpenter,
  'agriculture': Icons.agriculture,
  'cable': Icons.cable,
  'hardware': Icons.hardware,
  'table_restaurant': Icons.table_restaurant,
  'flashlight_on': Icons.flashlight_on,
  'medical_services': Icons.medical_services,
  'fire_extinguisher': Icons.fire_extinguisher,
  'toys': Icons.toys,
  'flag': Icons.flag,
  'propane_tank': Icons.propane_tank,
  'sanitizer': Icons.sanitizer,
  'backpack': Icons.backpack,
};

IconData itemTypeIcon(ItemType? type) =>
    _itemIcons[type?.icon] ?? Icons.backpack;

ItemType? itemTypeByKey(List<ItemType> types, String key) {
  for (final type in types) {
    if (type.key == key) return type;
  }
  return null;
}

/// Libellé et couleur de la pastille d'un matériel, comme le statut d'une
/// tente. Un problème signalé ou un stock bas passe avant le statut choisi.
ColorPair itemDisplayStatus(Item item, List<TentStatusRef> statuses) {
  TentStatusRef? byName(String name) {
    for (final s in statuses) {
      if (s.name.trim().toLowerCase() == name.toLowerCase()) return s;
    }
    return null;
  }

  if (item.usage == ItemUsage.out) {
    return ColorPair(
      label: 'Hors service',
      color: byName('HS')?.color ?? TentState.broken.bgColor,
    );
  }
  if (item.usage == ItemUsage.repair) {
    return ColorPair(
      label: 'À réparer',
      color: byName('À réparer')?.color ?? TentState.repair.bgColor,
    );
  }
  if (item.needsRestock) {
    return const ColorPair(label: 'À racheter', color: 0xFFFFE0B2);
  }
  for (final s in statuses) {
    if (s.id == item.statusId) return ColorPair(label: s.name, color: s.color);
  }
  return ColorPair(
    label: 'Bon',
    color: byName('Bon')?.color ?? TentState.good.bgColor,
  );
}

/// « 22 / 24 utilisables », « 20 L », « 4 restantes (seuil 10) »…
String itemQuantityLabel(Item item, ItemType? type) {
  if (item.isConsumable) {
    final threshold = item.threshold != null
        ? ' (seuil ${item.threshold})'
        : '';
    return '${item.quantity} en stock$threshold';
  }
  if (item.quantity > 1 || type?.tracking == ItemTracking.quantity) {
    if (item.usableQuantity < item.quantity) {
      return '${item.usableQuantity} / ${item.quantity} utilisables';
    }
    return '${item.quantity} pièces';
  }
  for (final field in type?.fields ?? const <ItemTypeField>[]) {
    final value = item.fields[field.key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return '${field.label} : $value';
    }
  }
  return '1 pièce';
}
