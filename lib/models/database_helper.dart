import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('logistiscout.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tentes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT,
        uniteId INTEGER,
        etat TEXT,
        remarques TEXT,
        tapisSolIntegre INTEGER,
        nbPlaces INTEGER,
        typeTente TEXT,
        unitePreferee TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE unites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE evenements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT,
        type TEXT,
        dateDebut TEXT,
        dateFin TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE evenement_materiel (
        evenementId INTEGER,
        materielId INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE reservations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debut TEXT,
        fin TEXT,
        evenementId INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE controles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenteId INTEGER,
        userId INTEGER,
        date TEXT,
        checklist TEXT,
        remarques TEXT
      )
    ''');
  }

  // CRUD Tentes
  Future<int> insertTente(Tente tente) async {
    final db = await database;
    return await db.insert('tentes', {
      'nom': tente.nom,
      'uniteId': tente.uniteId,
      'etat': tente.etat,
      'remarques': tente.remarques,
      'tapisSolIntegre': tente.tapisSolIntegre ? 1 : 0,
      'nbPlaces': tente.nbPlaces,
      'typeTente': tente.typeTente,
      'unitePreferee': tente.unitePreferee,
    });
  }

  Future<List<Tente>> getAllTentes() async {
    final db = await database;
    final result = await db.query('tentes');
    return result.map((json) => Tente(
      id: json['id'] as int,
      nom: json['nom'] as String,
      uniteId: json['uniteId'] as int?,
      etat: json['etat'] as String,
      remarques: json['remarques'] as String,
      tapisSolIntegre: (json['tapisSolIntegre'] ?? 0) == 1,
      nbPlaces: json['nbPlaces'] as int? ?? 0,
      typeTente: json['typeTente'] as String? ?? '',
      unitePreferee: json['unitePreferee'] as String? ?? '',
      agenda: [],
      historiqueControles: [],
    )).toList();
  }

  Future<Tente?> getTenteById(int id) async {
    final db = await database;
    final result = await db.query('tentes', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    // Récupérer les contrôles associés à cette tente
    final controlesResult = await db.query('controles', where: 'tenteId = ?', whereArgs: [id], orderBy: 'date DESC');
    final controles = controlesResult.map((json) => Controle(
      id: json['id'] as int,
      tenteId: json['tenteId'] as int,
      userId: json['userId'] as int? ?? 0,
      date: DateTime.parse(json['date'] as String),
      checklist: {}, // À parser si besoin
      remarques: json['remarques'] as String,
    )).toList();
    final json = result.first;
    return Tente(
      id: json['id'] as int,
      nom: json['nom'] as String,
      uniteId: json['uniteId'] as int?,
      etat: json['etat'] as String,
      remarques: json['remarques'] as String,
      tapisSolIntegre: (json['tapisSolIntegre'] ?? 0) == 1,
      nbPlaces: json['nbPlaces'] as int? ?? 0,
      typeTente: json['typeTente'] as String? ?? '',
      unitePreferee: json['unitePreferee'] as String? ?? '',
      agenda: [],
      historiqueControles: controles,
    );
  }

  Future<List<Unite>> getAllUnites() async {
    final db = await database;
    final result = await db.query('unites');
    return result.map((json) => Unite(
      id: json['id'] as int,
      nom: json['nom'] as String,
      tentesIds: [], // À compléter si besoin de lier les tentes à l'unité
    )).toList();
  }

  Future<int> updateTente(Tente tente) async {
    final db = await database;
    return await db.update(
      'tentes',
      {
        'nom': tente.nom,
        'uniteId': tente.uniteId,
        'etat': tente.etat,
        'remarques': tente.remarques,
      },
      where: 'id = ?',
      whereArgs: [tente.id],
    );
  }

  Future<int> deleteTente(int id) async {
    final db = await database;
    return await db.delete('tentes', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Unités
  Future<int> insertUnite(Unite unite) async {
    final db = await database;
    return await db.insert('unites', {
      'nom': unite.nom,
    });
  }

  Future<int> updateUnite(Unite unite) async {
    final db = await database;
    return await db.update(
      'unites',
      {
        'nom': unite.nom,
      },
      where: 'id = ?',
      whereArgs: [unite.id],
    );
  }

  Future<int> deleteUnite(int id) async {
    final db = await database;
    return await db.delete('unites', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Événements
  Future<int> insertEvenement(Evenement evt, DateTime dateFin, List<int> tentesAssociees) async {
    final db = await database;
    final id = await db.insert('evenements', {
      'nom': evt.nom,
      'type': evt.type ?? '',
      'dateDebut': evt.date.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
    });
    // Lier le matériel (tentes) à l'événement
    for (final tenteId in tentesAssociees) {
      await db.insert('evenement_materiel', {
        'evenementId': id,
        'materielId': tenteId,
      });
    }
    return id;
  }

  Future<List<Evenement>> getAllEvenements() async {
    final db = await database;
    final result = await db.query('evenements');
    List<Evenement> evenements = [];
    for (final row in result) {
      // Récupérer les tentes associées
      final tentesRows = await db.query('evenement_materiel', where: 'evenementId = ?', whereArgs: [row['id']]);
      final tentesAssociees = tentesRows.map((e) => e['materielId'] as int).toList();
      evenements.add(Evenement(
        id: row['id'] as int,
        nom: row['nom'] as String,
        date: DateTime.parse(row['dateDebut'] as String),
        tentesAssociees: tentesAssociees,
        type: row['type'] as String,
        dateFin: DateTime.parse(row['dateFin'] as String),
      ));
    }
    return evenements;
  }

  Future<int> deleteEvenement(int id) async {
    final db = await database;
    await db.delete('evenement_materiel', where: 'evenementId = ?', whereArgs: [id]);
    return await db.delete('evenements', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Réservations
  Future<int> insertReservation(Reservation reservation) async {
    final db = await database;
    return await db.insert('reservations', {
      'debut': reservation.debut.toIso8601String(),
      'fin': reservation.fin.toIso8601String(),
      'evenementId': reservation.evenementId,
    });
  }

  Future<List<Reservation>> getAllReservations() async {
    final db = await database;
    final result = await db.query('reservations');
    return result.map((json) => Reservation(
      debut: DateTime.parse(json['debut'] as String),
      fin: DateTime.parse(json['fin'] as String),
      evenementId: json['evenementId'] as int,
    )).toList();
  }

  Future<int> deleteReservation(int evenementId) async {
    final db = await database;
    return await db.delete('reservations', where: 'evenementId = ?', whereArgs: [evenementId]);
  }

  // CRUD Contrôles
  Future<int> insertControle(Controle controle) async {
    final db = await database;
    return await db.insert('controles', {
      'tenteId': controle.tenteId,
      'userId': controle.userId,
      'date': controle.date.toIso8601String(),
      'checklist': controle.checklist.toString(),
      'remarques': controle.remarques,
    });
  }

  Future<List<Controle>> getAllControles({int? tenteId}) async {
    final db = await database;
    final result = await db.query('controles', where: tenteId != null ? 'tenteId = ?' : null, whereArgs: tenteId != null ? [tenteId] : null);
    return result.map((json) => Controle(
      id: json['id'] as int,
      tenteId: json['tenteId'] as int,
      date: DateTime.parse(json['date'] as String),
      checklist: {}, // À parser si besoin
      remarques: json['remarques'] as String,
      userId: 0
    )).toList();
  }

  Future<int> deleteControle(int id) async {
    final db = await database;
    return await db.delete('controles', where: 'id = ?', whereArgs: [id]);
  }
}
