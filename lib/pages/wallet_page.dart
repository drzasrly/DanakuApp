import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  // Fungsi format rupiah agar tampilan profesional
  String formatRupiah(int nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(nominal);
  }

  // Menghitung total saldo dari semua wallet di AppData
  int get totalSaldo {
    return AppData.wallets.fold(0, (sum, item) => sum + item.saldo);
  }

  // --- FUNGSI TAMBAH WALLET ---
  void tambahWallet() {
    TextEditingController namaController = TextEditingController();
    TextEditingController saldoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Tambah Wallet Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: "Nama Wallet",
                hintText: "Contoh: BCA, Dompet, dll",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: saldoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Saldo Awal",
                prefixText: "Rp ",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (namaController.text.isNotEmpty) {
                final newWallet = Wallet(
                  nama: namaController.text,
                  saldo: int.tryParse(saldoController.text) ?? 0,
                );
                setState(() {
                  AppData.wallets.add(newWallet);
                });
                await DatabaseHelper.instance.saveWallets(AppData.wallets);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- FUNGSI EDIT WALLET ---
  void editWallet(int index) {
    TextEditingController namaController = TextEditingController(text: AppData.wallets[index].nama);
    TextEditingController saldoController = TextEditingController(text: AppData.wallets[index].saldo.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Edit Detail Wallet"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: "Nama Wallet"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: saldoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Saldo", prefixText: "Rp "),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              setState(() {
                AppData.wallets[index].nama = namaController.text;
                AppData.wallets[index].saldo = int.tryParse(saldoController.text) ?? 0;
              });
              await DatabaseHelper.instance.saveWallets(AppData.wallets);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- FUNGSI HAPUS WALLET ---
  void hapusWallet(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Hapus Wallet"),
        content: Text("Yakin ingin menghapus '${AppData.wallets[index].nama}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              setState(() {
                AppData.wallets.removeAt(index);
              });
              await DatabaseHelper.instance.saveWallets(AppData.wallets);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("My Wallets", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: tambahWallet,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: Column(
        children: [
          // HEADER CARD: TOTAL SALDO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.orangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total Saldo Seluruhnya",
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                FittedBox(
                  child: Text(
                    formatRupiah(totalSaldo),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Daftar Dompet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
          ),

          // LIST WALLET DENGAN FITUR EDIT & HAPUS
          Expanded(
            child: AppData.wallets.isEmpty
                ? const Center(child: Text("Belum ada wallet."))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: AppData.wallets.length,
              itemBuilder: (context, index) {
                final w = AppData.wallets[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                    ),
                    title: Text(w.nama,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Saldo Aktif", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          formatRupiah(w.saldo),
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.blueGrey, size: 28),
                          onPressed: () => editWallet(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                          onPressed: () => hapusWallet(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}