enum Unit {
  farfadets(name: "Farfadets", color: 0xFF65bc99),
  louvetaux(name: "Louveteaux-Jeanettes", color: 0xFFFF8300),
  scouts(name: "Scouts-Guides", color: 0xFF0077b3),
  pionnier(name: "Pionniers-Caravelles", color: 0xFFd03f15),
  compagnons(name: "Compagnons", color: 0xFF007254),
  maitrise(name: "Maitrise", color: 0xFF6e74aa),
  groupe(name: "Groupe", color: 0xFF420068),
  aucun(name: "Aucun", color: 0xFF000000),
  tous(name: "Tous", color: 0xFF909010);

  const Unit({required this.name, required this.color});

  final String name;
  final int color;

  Map<String, dynamic> toJson(Unit unit) {
    return {'name': unit.name, 'color': unit.color};
  }

  static Unit fromInt(int unitId) {
    return Unit.values[unitId];
  }

  static int toInt(Unit unit) {
    return unit.index;
  }

  static Unit fromString(String unitStr) {
    final normalized = unitStr.trim().toLowerCase();

    const aliases = {
      'louveteaux': 'louveteaux-jeanettes',
      'louveteaux-jeannettes': 'louveteaux-jeanettes',
      'louveteaux et jeannettes': 'louveteaux-jeanettes',
      'scouts': 'scouts-guides',
      'scouts et guides': 'scouts-guides',
      'pionniers': 'pionniers-caravelles',
      'pionniers et caravelles': 'pionniers-caravelles',
      'maitrise': 'groupe',
      'maîtrise': 'groupe',
    };

    final canonical = aliases[normalized] ?? normalized;

    return Unit.values.firstWhere(
      (e) => e.name.toLowerCase() == canonical,
      orElse: () => Unit.aucun,
    );
  }
}
