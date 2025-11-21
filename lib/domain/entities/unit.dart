enum Unit {

  Farfadets(name: "Farfadets", color: 0xFF81C784),
  Louvetaux(name: "Louveteaux-Jeanettes", color: 0xFFFFB74D),
  Scouts(name: "Scouts-Guides", color: 0xFF64B5F6),
  Pionnier(name: "Pionniers-Caravelles", color: 0xFFE57373),
  Compagnons(name: "Compagnons", color: 0xFF00790a),
  Maitrise(name: "Maitrise", color: 0xFFBA68C8),
  Groupe(name: "Groupe", color: 0xFF90A4AE),
  Aucun(name: "Aucun", color: 0xFFB0BEC5),
  Tous(name: "Tous", color: 0xFF455A64)
  ;

  const Unit({
    required this.name,
    required this.color,

});

  final String name;
  final int color;

  static Unit fromString(String unitStr) {
    return Unit.values.firstWhere(
      (e) => e.name.toLowerCase() == unitStr.toLowerCase(),
      orElse: () => Unit.Aucun,
    );
  }

}
