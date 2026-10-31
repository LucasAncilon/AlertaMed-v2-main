import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';
import '../models/patient.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'alertamed.db');
    return openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id        INTEGER DEFAULT 1,
        name              TEXT NOT NULL,
        dosage            TEXT NOT NULL,
        schedule          TEXT NOT NULL,
        frequency         TEXT NOT NULL DEFAULT '',
        notes             TEXT NOT NULL DEFAULT '',
        photo_path        TEXT DEFAULT '',
        notification_time TEXT DEFAULT '',
        voice_reminder    INTEGER DEFAULT 0
      )
    ''');
    await _createPatientTable(db);
    await _seedDemoData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPatientTable(db);
    }
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE medications ADD COLUMN frequency TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE medications ADD COLUMN photo_path TEXT DEFAULT ''");
      await db.execute("ALTER TABLE medications ADD COLUMN notification_time TEXT DEFAULT ''");
      await db.execute("ALTER TABLE medications ADD COLUMN voice_reminder INTEGER DEFAULT 0");
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE medications ADD COLUMN patient_id INTEGER DEFAULT 1");
    }
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE patient ADD COLUMN is_demo INTEGER DEFAULT 0");
    }
  }

  Future<void> _createPatientTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patient (
        id                INTEGER PRIMARY KEY,
        name              TEXT NOT NULL,
        age               INTEGER NOT NULL,
        blood_type        TEXT,
        allergies         TEXT,
        emergency_contact TEXT,
        caregiver_name    TEXT,
        caregiver_phone   TEXT,
        notes             TEXT,
        is_demo           INTEGER DEFAULT 0
      )
    ''');
  }

  // Inserido apenas na criação do banco (fresh install).
  Future<void> _seedDemoData(Database db) async {
    await db.insert('patient', {
      'id': 1,
      'name': 'Pessoa de demonstração',
      'age': 70,
      'blood_type': 'O+',
      'allergies': 'Penicilina',
      'emergency_contact': 'Familiar - (11) 99999-9999',
      'caregiver_name': 'Familiar responsável',
      'caregiver_phone': '(11) 99999-9999',
      'notes': 'Este é um cadastro de exemplo. Edite ou exclua para começar.',
      'is_demo': 1,
    });
    await db.insert('medications', {
      'patient_id': 1,
      'name': 'Losartana',
      'dosage': '50mg',
      'schedule': '08:00',
      'frequency': '1x ao dia',
      'notes': 'Tomar com água em jejum',
      'notification_time': '08:00',
    });
    await db.insert('medications', {
      'patient_id': 1,
      'name': 'Metformina',
      'dosage': '500mg',
      'schedule': '12:00 e 19:00',
      'frequency': '2x ao dia',
      'notes': 'Tomar durante a refeição',
      'notification_time': '12:00',
    });
    await db.insert('medications', {
      'patient_id': 1,
      'name': 'Sinvastatina',
      'dosage': '20mg',
      'schedule': '22:00',
      'frequency': '1x ao dia',
      'notes': '',
      'notification_time': '22:00',
    });
  }

  // --- Medications ---

  Future<int> insertMedication(Medication medication) async {
    final db = await database;
    return db.insert('medications', medication.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    final map = medication.toMap()..remove('id');
    return db.update('medications', map,
        where: 'id = ?', whereArgs: [medication.id]);
  }

  Future<List<Medication>> getMedicationsByPatient(int patientId) async {
    final db = await database;
    final maps = await db.query(
      'medications',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'name ASC',
    );
    return maps.map(Medication.fromMap).toList();
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  // --- Patients ---

  Future<List<Patient>> getPatients() async {
    final db = await database;
    final maps = await db.query('patient', orderBy: 'name ASC');
    return maps.map(Patient.fromMap).toList();
  }

  Future<Patient?> getPatientById(int id) async {
    final db = await database;
    final maps = await db.query('patient', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    final map = patient.toMap()..remove('id');
    return db.insert('patient', map);
  }

  Future<void> updatePatient(Patient patient) async {
    final db = await database;
    final map = patient.toMap()..remove('id');
    await db.update('patient', map, where: 'id = ?', whereArgs: [patient.id]);
  }

  Future<void> deletePatient(int id) async {
    final db = await database;
    await db.delete('medications', where: 'patient_id = ?', whereArgs: [id]);
    await db.delete('patient', where: 'id = ?', whereArgs: [id]);
  }
}
