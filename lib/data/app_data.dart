import 'package:flutter/material.dart';

class Wallet {
  String nama;
  int saldo;
  String jenis; // "Hutang", "Akun Virtual", "Aset", etc.
  IconData icon;

  Wallet({
    required this.nama, 
    required this.saldo, 
    this.jenis = "Akun Virtual", 
    this.icon = Icons.credit_card_rounded
  });
}

class Transaksi {
  final int? id;
  final String keterangan;
  final int jumlah;
  final String jenis; // "masuk" atau "keluar"
  final DateTime tanggal;
  final String walletNama;
  final String kategori;

  Transaksi({
    this.id,
    required this.keterangan,
    required this.jumlah,
    required this.jenis,
    required this.tanggal,
    required this.walletNama,
    required this.kategori,
  });

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'],
      keterangan: map['keterangan'] ?? '',
      jumlah: map['jumlah'] ?? 0,
      jenis: map['jenis'] ?? '',
      tanggal: DateTime.parse(map['tanggal']),
      walletNama: map['walletNama'] ?? '',
      kategori: map['kategori'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keterangan': keterangan,
      'jumlah': jumlah,
      'jenis': jenis,
      'tanggal': tanggal.toIso8601String(),
      'walletNama': walletNama,
      'kategori': kategori,
    };
  }
}

class TransactionCategory {
  final int? id;
  final String nama;
  final IconData? icon;
  final String? imagePath;

  TransactionCategory({this.id, required this.nama, this.icon, this.imagePath});

  Map<String, dynamic> toMap(String jenis) {
    return {
      'id': id,
      'nama': nama,
      'jenis': jenis,
      'icon_code': icon?.codePoint,
      'image_path': imagePath,
    };
  }

  factory TransactionCategory.fromMap(Map<String, dynamic> map) {
    return TransactionCategory(
      id: map['id'],
      nama: map['nama'],
      icon: map['icon_code'] != null ? IconData(map['icon_code'], fontFamily: 'MaterialIcons') : null,
      imagePath: map['image_path'],
    );
  }
}

class AppData {
  static List<Wallet> wallets = [
    Wallet(nama: "Utama", saldo: 0, jenis: "Akun Virtual", icon: Icons.account_balance_wallet),
  ];

  static List<Transaksi> transaksi = [];
  
  static List<TransactionCategory> pengeluaranCategories = [
    TransactionCategory(nama: "Makan", imagePath: "assets/icons/makan.png"),
    TransactionCategory(nama: "Minum", imagePath: "assets/icons/minum.png"),
    TransactionCategory(nama: "Bensin", imagePath: "assets/icons/bensin.png"),
    TransactionCategory(nama: "Parkir", icon: Icons.local_parking_rounded),
    TransactionCategory(nama: "Kopi", icon: Icons.coffee_rounded),
    TransactionCategory(nama: "Sosial", icon: Icons.auto_awesome_rounded),
    TransactionCategory(nama: "Harian", icon: Icons.shopping_bag_rounded),
    TransactionCategory(nama: "Admin", icon: Icons.account_balance_rounded),
    TransactionCategory(nama: "Hadiah", icon: Icons.card_giftcard_rounded),
    TransactionCategory(nama: "Ban", icon: Icons.tire_repair_rounded),
    TransactionCategory(nama: "Jalan", icon: Icons.traffic_rounded),
    TransactionCategory(nama: "HP", icon: Icons.phone_android_rounded),
  ];

  static List<TransactionCategory> pemasukanCategories = [
    TransactionCategory(nama: "Gaji", imagePath: "assets/icons/gaji.png"),
    TransactionCategory(nama: "Uang Saku", icon: Icons.account_balance_wallet_rounded),
    TransactionCategory(nama: "Bonus", icon: Icons.star_rounded),
    TransactionCategory(nama: "Lainnya", icon: Icons.auto_graph_rounded),
  ];
}
