import 'package:flutter/material.dart';

class Wallet {
  String nama;
  int saldo;

  Wallet({required this.nama, required this.saldo});
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



  // Mengubah data dari Map (database) ke Objek Transaksi (Flutter)
  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'],
      keterangan: map['keterangan'] ?? '',
      jumlah: map['jumlah'] ?? 0,
      jenis: map['jenis'] ?? '',
      tanggal: DateTime.parse(map['tanggal']), // Mengubah string database ke DateTime
      walletNama: map['walletNama'] ?? '',
      kategori: map['kategori'] ?? '',
    );
  }

  // Mengubah Objek Transaksi ke Map (untuk disimpan ke database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keterangan': keterangan,
      'jumlah': jumlah,
      'jenis': jenis,
      'tanggal': tanggal.toIso8601String(), // Simpan DateTime sebagai String
      'walletNama': walletNama,
      'kategori': kategori,
    };
  }
}

class AppData {
  static List<Wallet> wallets = [
    Wallet(nama: "Utama", saldo: 0),
  ];

  // Ubah kembali ke 'transaksi' (huruf kecil semua)
  static List<Transaksi> transaksi = [];
}
