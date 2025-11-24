enum Unit {

  Farfadets(name: "Farfadets", color: 0xFF65bc99),
  Louvetaux(name: "Louveteaux-Jeanettes", color: 0xFFFF8300),
  Scouts(name: "Scouts-Guides", color: 0xFF0077b3),
  Pionnier(name: "Pionniers-Caravelles", color: 0xFFd03f15),
  Compagnons(name: "Compagnons", color: 0xFF007254),
  Maitrise(name: "Maitrise", color: 0xFF6e74aa),
  Groupe(name: "Groupe", color: 0xFF420068),
  Aucun(name: "Aucun", color: 0xFF000000),
  Tous(name: "Tous", color: 0xFF909010)
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
