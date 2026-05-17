import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'app_data.dart';
import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_app_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
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

    await db.execute('''
    CREATE TABLE wallets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT,
      saldo INTEGER,
      jenis TEXT,
      icon_code INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT,
      jenis TEXT,
      icon_code INTEGER,
      image_path TEXT
    )
    ''');

    // Insert default wallets from AppData (now only contains "Utama")
    for (var w in AppData.wallets) {
      await db.insert('wallets', {
        'nama': w.nama, 
        'saldo': w.saldo, 
        'jenis': w.jenis, 
        'icon_code': w.icon.codePoint
      });
    }
    
    // Insert default categories
    for (var cat in AppData.pengeluaranCategories) {
      await db.insert('categories', cat.toMap('keluar'));
    }
    for (var cat in AppData.pemasukanCategories) {
      await db.insert('categories', cat.toMap('masuk'));
    }
  }

  // Categories functions
  Future<List<TransactionCategory>> fetchCategories(String jenis) async {
    final db = await database;
    final result = await db.query('categories', where: 'jenis = ?', whereArgs: [jenis]);
    return result.map((json) => TransactionCategory.fromMap(json)).toList();
  }

  Future<void> insertCategory(TransactionCategory cat, String jenis) async {
    final db = await database;
    await db.insert('categories', cat.toMap(jenis));
    // Trigger pencadangan otomatis senyap di background
    SyncService.instance.triggerAutoBackup();
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    // Trigger pencadangan otomatis senyap di background
    SyncService.instance.triggerAutoBackup();
  }

  // --- FUNGSI SETTINGS (UNTUK OFFLINE KURS) ---
  Future<void> saveLastRate(double rate) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'last_idr_rate', 'value': rate.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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
    return 15800.0;
  }

  // --- FUNGSI PENGATURAN GENERIK (UNTUK AUTH & BACKUP SIMULASI) ---
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key]
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete(
      'settings',
      where: 'key = ?',
      whereArgs: [key]
    );
  }

  // --- FUNGSI TRANSAKSI ---
  Future<void> insertTransaksi(Transaksi t) async {
    final db = await database;
    await db.insert('transaksi', t.toMap());

    final List<Map<String, dynamic>> walletMaps = await db.query(
      'wallets',
      where: 'nama = ?',
      whereArgs: [t.walletNama],
    );

    if (walletMaps.isNotEmpty) {
      int saldoSekarang = walletMaps.first['saldo'] as int;
      int saldoBaru;
      if (t.jenis.toLowerCase() == 'keluar' || t.jenis.toLowerCase() == 'pengeluaran') {
        saldoBaru = saldoSekarang - t.jumlah;
      } else {
        saldoBaru = saldoSekarang + t.jumlah;
      }
      await db.update('wallets', {'saldo': saldoBaru}, where: 'nama = ?', whereArgs: [t.walletNama]);
    }

    // Trigger pencadangan otomatis senyap di background jika user login
    SyncService.instance.triggerAutoBackup();
  }

  Future<List<Transaksi>> fetchTransaksi() async {
    final db = await database;
    final result = await db.query('transaksi', orderBy: 'tanggal DESC');
    return result.map((json) => Transaksi.fromMap(json)).toList();
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    final db = await database;
    await db.delete('wallets');
    for (var w in wallets) {
      await db.insert('wallets', {
        'nama': w.nama, 
        'saldo': w.saldo, 
        'jenis': w.jenis, 
        'icon_code': w.icon.codePoint
      });
    }
  }

  Future<List<Wallet>> fetchWallets() async {
    final db = await database;
    final result = await db.query('wallets');
    return result.map((json) => Wallet(
      nama: json['nama'] as String, 
      saldo: json['saldo'] as int,
      jenis: json['jenis'] != null ? json['jenis'] as String : "Akun Virtual",
      icon: json['icon_code'] != null ? IconData(json['icon_code'] as int, fontFamily: 'MaterialIcons') : Icons.account_balance_wallet
    )).toList();
  }

  Future<void> deleteTransaksi(Transaksi t) async {
    final db = await database;
    
    // Reverse the wallet balance
    final List<Map<String, dynamic>> walletMaps = await db.query(
      'wallets',
      where: 'nama = ?',
      whereArgs: [t.walletNama],
    );

    if (walletMaps.isNotEmpty) {
      int saldoSekarang = walletMaps.first['saldo'] as int;
      int saldoBaru;
      if (t.jenis.toLowerCase() == 'keluar' || t.jenis.toLowerCase() == 'pengeluaran') {
        saldoBaru = saldoSekarang + t.jumlah;
      } else {
        saldoBaru = saldoSekarang - t.jumlah;
      }
      await db.update('wallets', {'saldo': saldoBaru}, where: 'nama = ?', whereArgs: [t.walletNama]);
    }

    await db.delete('transaksi', where: 'id = ?', whereArgs: [t.id]);
    // Trigger pencadangan otomatis senyap di background jika user login
    SyncService.instance.triggerAutoBackup();
  }

  Future<void> updateTransaksi(Transaksi oldT, Transaksi newT) async {
    final db = await database;

    // 1. Reverse old impact
    final List<Map<String, dynamic>> oldWalletMaps = await db.query(
      'wallets',
      where: 'nama = ?',
      whereArgs: [oldT.walletNama],
    );

    if (oldWalletMaps.isNotEmpty) {
      int saldoSekarang = oldWalletMaps.first['saldo'] as int;
      int reversedSaldo;
      if (oldT.jenis.toLowerCase() == 'keluar' || oldT.jenis.toLowerCase() == 'pengeluaran') {
        reversedSaldo = saldoSekarang + oldT.jumlah;
      } else {
        reversedSaldo = saldoSekarang - oldT.jumlah;
      }
      await db.update('wallets', {'saldo': reversedSaldo}, where: 'nama = ?', whereArgs: [oldT.walletNama]);
    }

    // 2. Apply new impact
    final List<Map<String, dynamic>> newWalletMaps = await db.query(
      'wallets',
      where: 'nama = ?',
      whereArgs: [newT.walletNama],
    );

    if (newWalletMaps.isNotEmpty) {
      int saldoTarget;
      if (oldT.walletNama == newT.walletNama) {
        final updatedWallet = await db.query('wallets', where: 'nama = ?', whereArgs: [newT.walletNama]);
        saldoTarget = updatedWallet.first['saldo'] as int;
      } else {
        saldoTarget = newWalletMaps.first['saldo'] as int;
      }

      int saldoBaru;
      if (newT.jenis.toLowerCase() == 'keluar' || newT.jenis.toLowerCase() == 'pengeluaran') {
        saldoBaru = saldoTarget - newT.jumlah;
      } else {
        saldoBaru = saldoTarget + newT.jumlah;
      }
      await db.update('wallets', {'saldo': saldoBaru}, where: 'nama = ?', whereArgs: [newT.walletNama]);
    }

    await db.update('transaksi', newT.toMap(), where: 'id = ?', whereArgs: [oldT.id]);
    // Trigger pencadangan otomatis senyap di background jika user login
    SyncService.instance.triggerAutoBackup();
  }

  Future<void> resetData() async {
    final db = await database;
    await db.delete('transaksi');
    await db.delete('wallets');
    await db.insert('wallets', {
      'nama': 'Utama',
      'saldo': 0,
      'jenis': 'Akun Virtual',
      'icon_code': Icons.account_balance_wallet.codePoint,
    });
    // Trigger pencadangan otomatis senyap di background jika user login
    SyncService.instance.triggerAutoBackup();
  }
}