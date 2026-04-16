import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'app_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Naikkan versi ke 2 jika kamu sudah pernah menjalankan app sebelumnya
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabel Transaksi
    await db.execute('''
    CREATE TABLE transaksi (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keterangan TEXT,
      jumlah INTEGER,
      jenis TEXT,
      tanggal TEXT,
      walletNama TEXT,
      kategori TEXT
    )
    ''');

    // Tabel Wallet
    await db.execute('''
    CREATE TABLE wallets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT,
      saldo INTEGER
    )
    ''');

    // --- LANGKAH 1: TABEL SETTINGS UNTUK KURS ---
    await db.execute('''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
    ''');

    // Opsional: Tambahkan wallet default
    await db.insert('wallets', {'nama': 'Utama', 'saldo': 0});
  }

  // --- FUNGSI SETTINGS (UNTUK OFFLINE KURS) ---

  // Menyimpan kurs terbaru ke database
  Future<void> saveLastRate(double rate) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'last_idr_rate', 'value': rate.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Mengambil kurs terakhir yang tersimpan
  Future<double> getLastRate() async {
    final db = await database;
    final maps = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['last_idr_rate']
    );

    if (maps.isNotEmpty) {
      return double.tryParse(maps.first['value'] as String) ?? 15800.0;
    }
    return 15800.0; // Nilai default jika belum pernah simpan
  }

  // --- FUNGSI TRANSAKSI ---
  Future<void> insertTransaksi(Transaksi t) async {
    final db = await database;

    await db.insert('transaksi', {
      'keterangan': t.keterangan,
      'jumlah': t.jumlah,
      'jenis': t.jenis,
      'tanggal': t.tanggal.toIso8601String(),
      'walletNama': t.walletNama,
      'kategori': t.kategori,
    });

    final List<Map<String, dynamic>> walletMaps = await db.query(
      'wallets',
      where: 'nama = ?',
      whereArgs: [t.walletNama],
    );

    if (walletMaps.isNotEmpty) {
      int saldoSekarang = walletMaps.first['saldo'];
      int saldoBaru;

      // Note: Sesuaikan dengan string yang kamu pakai (keluar/pengeluaran)
      if (t.jenis.toLowerCase() == 'keluar' || t.jenis.toLowerCase() == 'pengeluaran') {
        saldoBaru = saldoSekarang - t.jumlah;
      } else {
        saldoBaru = saldoSekarang + t.jumlah;
      }

      await db.update(
        'wallets',
        {'saldo': saldoBaru},
        where: 'nama = ?',
        whereArgs: [t.walletNama],
      );
    }
  }

  Future<List<Transaksi>> fetchTransaksi() async {
    final db = await database;
    final result = await db.query('transaksi', orderBy: 'id ASC');
    return result.map((json) => Transaksi(
      keterangan: json['keterangan'] as String,
      jumlah: json['jumlah'] as int,
      jenis: json['jenis'] as String,
      tanggal: DateTime.parse(json['tanggal'] as String),
      walletNama: json['walletNama'] as String,
      kategori: json['kategori'] as String,
    )).toList();
  }

  // --- FUNGSI WALLET ---
  Future<void> saveWallets(List<Wallet> wallets) async {
    final db = await database;
    await db.delete('wallets');
    for (var w in wallets) {
      await db.insert('wallets', {'nama': w.nama, 'saldo': w.saldo});
    }
  }

  Future<List<Wallet>> fetchWallets() async {
    final db = await database;
    final result = await db.query('wallets');
    return result.map((json) => Wallet(
      nama: json['nama'] as String,
      saldo: json['saldo'] as int,
    )).toList();
  }
}