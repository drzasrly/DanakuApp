import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  // Hitung Total Saldo Otomatis
  int get totalSaldo {
    return AppData.wallets.fold(0, (sum, item) => sum + item.saldo);
  }

  //  TAMBAH WALLET
  void tambahWallet() {
    TextEditingController namaController = TextEditingController();
    TextEditingController saldoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Wallet"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: "Nama Wallet"),
            ),
            TextField(
              controller: saldoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Saldo Awal"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async { // Tambahkan async di sini
              if (namaController.text.isNotEmpty) {
                final newWallet = Wallet(
                  nama: namaController.text,
                  saldo: int.tryParse(saldoController.text) ?? 0,
                );

                setState(() {
                  AppData.wallets.add(newWallet);
                });

                // SIMPAN KE DATABASE LOKAL
                await DatabaseHelper.instance.saveWallets(AppData.wallets);

                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  // EDIT WALLET
  void editWallet(int index) {
    TextEditingController namaController = TextEditingController(text: AppData.wallets[index].nama);
    TextEditingController saldoController = TextEditingController(text: AppData.wallets[index].saldo.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Wallet"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: "Nama Wallet"),
            ),
            TextField(
              controller: saldoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Saldo"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async { // Tambahkan async di sini
              setState(() {
                AppData.wallets[index].nama = namaController.text;
                AppData.wallets[index].saldo = int.tryParse(saldoController.text) ?? 0;
              });

              // SIMPAN KE DATABASE LOKAL (Update list terbaru)
              await DatabaseHelper.instance.saveWallets(AppData.wallets);

              if (mounted) Navigator.pop(context);
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton(
        onPressed: tambahWallet,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // HEADER TOTAL SALDO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total Saldo Seluruhnya", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  "Rp $totalSaldo",
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // LIST WALLET
          Expanded(
            child: AppData.wallets.isEmpty
                ? const Center(child: Text("Belum ada wallet."))
                : ListView.builder(
              itemCount: AppData.wallets.length,
              itemBuilder: (context, index) {
                final w = AppData.wallets[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                    ),
                    title: Text(w.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("Saldo Aktif", style: TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            "Rp ${w.saldo}",
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.grey),
                          onPressed: () => editWallet(index),
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