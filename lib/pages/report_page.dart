import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Tambahkan package intl
import '../data/app_data.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  // Index 0: Harian (Realtime), Index 1: Bulanan (Monthly)
  List<bool> isSelected = [true, false];

  final Map<String, Color> warnaKategori = {
    "Makan": Colors.redAccent,
    "Transport": Colors.blueAccent,
    "Belanja": Colors.orangeAccent,
    "Tagihan": Colors.purpleAccent,
    "Hiburan": Colors.pinkAccent,
    "Lainnya": Colors.grey,
  };

  /// FUNGSI 1: Memfilter data transaksi (Logika dari Code 2)
  List<dynamic> getFilteredTransactions() {
    DateTime now = DateTime.now();

    return AppData.transaksi.where((t) {
      if (t.jenis != "keluar") return false;

      if (isSelected[0]) {
        // Logika Realtime dari Code 2
        return t.tanggal.day == now.day &&
            t.tanggal.month == now.month &&
            t.tanggal.year == now.year;
      } else {
        // Logika Monthly dari Code 2
        return t.tanggal.month == now.month &&
            t.tanggal.year == now.year;
      }
    }).toList();
  }

  /// Menghasilkan label rentang tanggal sesuai Code 2
  String getDateRangeLabel() {
    DateTime now = DateTime.now();
    if (isSelected[1]) {
      // Format Bulanan: 01 Jan 2026 - 31 Jan 2026
      String start = "01 ${DateFormat('MMM yyyy').format(now)}";
      int lastDay = DateTime(now.year, now.month + 1, 0).day;
      String end = "$lastDay ${DateFormat('MMM yyyy').format(now)}";
      return "$start - $end";
    } else {
      // Format Harian
      return DateFormat('dd MMM yyyy').format(now);
    }
  }

  List<PieChartSectionData> getSections(List<dynamic> filteredList) {
    Map<String, double> ringkasanKategori = {};
    double totalNilai = 0;

    for (var t in filteredList) {
      ringkasanKategori[t.kategori] = (ringkasanKategori[t.kategori] ?? 0) + t.jumlah;
      totalNilai += t.jumlah;
    }

    if (ringkasanKategori.isEmpty) return [];

    return ringkasanKategori.entries.map((e) {
      final double persen = (e.value / totalNilai) * 100;
      return PieChartSectionData(
        color: warnaKategori[e.key] ?? Colors.teal,
        value: e.value,
        title: "${persen.toStringAsFixed(0)}%",
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = getFilteredTransactions();
    final sections = getSections(filteredData);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Pengeluaran", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // TOMBOL SWITCH
          Center(
            child: ToggleButtons(
              isSelected: isSelected,
              onPressed: (index) {
                setState(() {
                  for (int i = 0; i < isSelected.length; i++) {
                    isSelected[i] = i == index;
                  }
                });
              },
              borderRadius: BorderRadius.circular(25),
              constraints: const BoxConstraints(minHeight: 40, minWidth: 130),
              selectedColor: Colors.white,
              fillColor: Colors.orange,
              color: Colors.orange,
              children: const [
                Text("Harian", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Bulanan", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // TAMPILAN RENTANG TANGGAL (Penerapan dari Code 2)
          Text(
            getDateRangeLabel(),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),

          const SizedBox(height: 20),

          // AREA GRAFIK
          SizedBox(
            height: 200,
            child: sections.isNotEmpty
                ? PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 3,
                centerSpaceRadius: 40,
              ),
            )
                : const Center(
              child: Text("Tidak ada data pengeluaran\nuntuk periode ini",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(thickness: 1, indent: 20, endIndent: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Rincian Kategori",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          Expanded(
            child: filteredData.isNotEmpty
                ? ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: warnaKategori.keys.map((namaKategori) {
                double totalPerKategori = filteredData
                    .where((t) => t.kategori == namaKategori)
                    .fold(0, (sum, item) => sum + item.jumlah);

                if (totalPerKategori == 0) return const SizedBox();

                return Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: Icon(Icons.circle, color: warnaKategori[namaKategori], size: 18),
                    title: Text(namaKategori, style: const TextStyle(fontSize: 14)),
                    trailing: Text(
                      "Rp ${NumberFormat.decimalPattern('id').format(totalPerKategori)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                );
              }).toList(),
            )
                : const Center(child: Text("Daftar kosong")),
          ),
        ],
      ),
    );
  }
}