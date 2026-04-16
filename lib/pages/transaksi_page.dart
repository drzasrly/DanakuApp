import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../services/export_service.dart';
import '../data/app_data.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  List<Transaksi> allTransaksi = [];
  List<Transaksi> filteredTransaksi = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() async {
    final data = await DatabaseHelper.instance.fetchTransaksi();
    setState(() {
      // Urutkan dari yang terbaru (tanggal terbaru di atas)
      allTransaksi = data.reversed.toList();
      filteredTransaksi = allTransaksi;
    });
  }

  void _filterSearch(String query) {
    setState(() {
      filteredTransaksi = allTransaksi
          .where((t) => t.keterangan.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _handleExport() async {
    try {
      // Tampilkan Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      String filePath = await ExportService.exportTransaksiToCSV();

      if (mounted) {
        Navigator.pop(context); // Tutup Loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Berhasil ekspor ke: $filePath"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup Loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal melakukan ekspor"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
            "Semua Transaksi",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.blueAccent),
            onPressed: _handleExport,
            tooltip: "Export CSV",
          ),
          const SizedBox(width: 8),
        ],
        // --- SEARCH BAR DI BAGIAN BOTTOM APPBAR ---
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: TextField(
              controller: searchController,
              onChanged: _filterSearch,
              decoration: InputDecoration(
                hintText: "Cari keterangan transaksi...",
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    _filterSearch("");
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF4F7F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: filteredTransaksi.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text("Tidak ada riwayat transaksi", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async => _loadAllData(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredTransaksi.length,
          itemBuilder: (context, index) {
            final t = filteredTransaksi[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: t.jenis == "masuk" || t.jenis == "Pemasukan"
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  child: Icon(
                    t.jenis == "masuk" || t.jenis == "Pemasukan"
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: t.jenis == "masuk" || t.jenis == "Pemasukan" ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                    t.keterangan,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                ),
                subtitle: Text(
                  "${DateFormat('dd MMM yyyy').format(t.tanggal)} • ${t.walletNama}",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Rp ${NumberFormat.decimalPattern('id').format(t.jumlah)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: t.jenis == "masuk" || t.jenis == "Pemasukan" ? Colors.green : Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      t.kategori,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}