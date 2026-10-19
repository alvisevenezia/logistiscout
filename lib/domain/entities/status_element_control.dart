enum StatusElementControl { ok, ko;

  bool toJson() {
    switch (this) {
      case StatusElementControl.ok:
        return true;
      case StatusElementControl.ko:
        return false;
    }
  }
}

/// Statuts OK/KO d'un contrôle enregistré (`true` = OK, `false` = KO) ;
/// les autres champs de la checklist (sardines, contrôleur…) sont ignorés.
Map<String, StatusElementControl> controlItemStatuses(
  Map<String, dynamic> checklist,
) {
  return {
    for (final entry in checklist.entries)
      if (entry.value is bool)
        entry.key: entry.value as bool
            ? StatusElementControl.ok
            : StatusElementControl.ko,
  };
}
