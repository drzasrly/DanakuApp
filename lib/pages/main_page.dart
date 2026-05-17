import 'package:flutter/material.dart';
import 'home_page.dart';
import 'wallet_page.dart';
import 'report_page.dart';
import 'transaction_input_page.dart';

import 'setting_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;


  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const WalletPage();
      case 2:
        return const ReportPage();
      case 3:
        return const SettingPage();
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(currentIndex),
      floatingActionButton: currentIndex == 0 ? FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () async {
          final result = await showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("Pengeluaran"),
                  onTap: () => Navigator.pop(context, "keluar"),
                ),
                ListTile(
                  title: const Text("Pemasukan"),
                  onTap: () => Navigator.pop(context, "masuk"),
                ),
                ListTile(
                  title: const Text("Manage"),
                  onTap: () => Navigator.pop(context, "manage"),
                ),
              ],
            ),
          );

          if (result != null) {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionInputPage(initialJenis: result),
              ),
            );
          }
        },
        child: const Icon(Icons.add, color: Colors.pink),
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Report"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Setting"),
        ],
      ),
    );
  }
}