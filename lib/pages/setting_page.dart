import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/app_data.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  void _resetData(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Data"),
        content: const Text("Apakah Anda yakin ingin menghapus semua transaksi dan meriset saldo dompet ke 0? Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Ya, Reset", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.resetData();
      AppData.transaksi.clear();
      AppData.wallets = [
        Wallet(nama: "Utama", saldo: 0, jenis: "Akun Virtual", icon: Icons.account_balance_wallet)
      ];
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data berhasil direset ke nol.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        title: const Text("Pengaturan", style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSettingItem(
            context,
            icon: Icons.refresh,
            title: "Reset Semua Data",
            subtitle: "Hapus transaksi & nol-kan saldo",
            color: Colors.red,
            onTap: () => _resetData(context),
          ),
          _buildSettingItem(
            context,
            icon: Icons.info_outline,
            title: "Tentang Aplikasi",
            subtitle: "DanakuApp v1.0.0",
            color: Colors.blue,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
