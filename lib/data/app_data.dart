import 'package:flutter/material.dart';

class Wallet {
  String nama;
  int saldo;

  Wallet({required this.nama, required this.saldo});
}

class Transaksi {
  final String keterangan;
  final int jumlah;
  final String jenis;
  final DateTime tanggal;
  final String walletNama;
  final String kategori;

  Transaksi({
    required this.keterangan,
    required this.jumlah,
    required this.jenis,
    required this.tanggal,
    required this.walletNama,
    required this.kategori,
  });
}

class AppData {
  // Wallet default
  static List<Wallet> wallets = [
    Wallet(nama: "Utama", saldo: 0)
  ];

  static List<Transaksi> transaksi = [];
}