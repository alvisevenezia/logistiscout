import 'package:flutter/cupertino.dart';

enum MenuType {

  petitDejeuner(name: "Petit Déjeuner", icon: Icon(CupertinoIcons.sunrise)),
  entree(name: "Entrée", icon: Icon(CupertinoIcons.archivebox)),
  plat(name: "Plat", icon: Icon(CupertinoIcons.flame)),
  fromage(name: "Fromage", icon: Icon(CupertinoIcons.check_mark)),
  dessert(name: "Dessert", icon: Icon(CupertinoIcons.arrow_down_left_circle)),

  ;

  const MenuType({
    required this.name,
    required this.icon,
  });

  final String name;
  final Icon icon;

  static MenuType fromInt(int unitId) {
    return MenuType.values[unitId];

  }

  static int toInt(MenuType unit) {
    return unit.index;
  }

  static MenuType fromString(String unitStr) {
    return MenuType.values.firstWhere(
          (e) => e.name.toLowerCase() == unitStr.toLowerCase(),
      orElse: () => MenuType.plat,
    );
  }

}
