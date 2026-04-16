import 'package:app_petama/pages/report_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'wallet_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const HomePage(),
    const Center(child: Text("Transaksi")),
    const WalletPage(),
    const ReportPage(),
    const Center(child: Text("Setting")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.list), label: "Transaksi"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: "Wallet"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Report"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Setting"),
        ],
      ),
    );
  }
}