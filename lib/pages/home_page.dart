import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import '../services/exchange_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> daftarKategori = ["Makan", "Transport", "Belanja", "Tagihan", "Hiburan", "Lainnya"];
  DateTime selectedDate = DateTime.now();
  final ExchangeService _exchangeService = ExchangeService();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // Fungsi untuk refresh data dari SQLite ke variabel global AppData
  Future<void> _initData() async {
    final listT = await DatabaseHelper.instance.fetchTransaksi();
    final listW = await DatabaseHelper.instance.fetchWallets();

    setState(() {
      AppData.transaksi = listT;
      AppData.wallets = listW;

      if (AppData.wallets.isEmpty) {
        AppData.wallets = [Wallet(nama: "Utama", saldo: 0)];
        DatabaseHelper.instance.saveWallets(AppData.wallets);
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void showInputDialog(String jenis) {
    if (jenis == "keluar" && AppData.wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tambahkan wallet terlebih dahulu!")),
      );
      return;
    }

    final TextEditingController ketController = TextEditingController();
    final TextEditingController jmlController = TextEditingController();
    final TextEditingController usdController = TextEditingController();

    int? selectedWalletIndex = AppData.wallets.isNotEmpty ? 0 : null;
    String selectedKategori = "Lainnya";
    double currentRate = 15800.0;
    bool isFetchingKurs = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double screenWidth = MediaQuery.of(context).size.width;
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? screenWidth * 0.2 : 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                jenis == "masuk" ? "Tambah Pemasukan" : "Catat Pengeluaran",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: jenis == "masuk" ? Colors.green : Colors.red
                ),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                          controller: ketController,
                          decoration: const InputDecoration(labelText: "Keterangan", hintText: "Misal: Jajan Makan Siang")
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: usdController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "USD", prefixText: "\$ "),
                              onChanged: (val) async {
                                if (val.isNotEmpty) {
                                  setDialogState(() => isFetchingKurs = true);
                                  try {
                                    final data = await _exchangeService.fetchRates();
                                    currentRate = data['rates']['IDR'].toDouble();
                                    await DatabaseHelper.instance.saveLastRate(currentRate);
                                  } catch (e) {
                                    currentRate = await DatabaseHelper.instance.getLastRate();
                                  }
                                  double usdVal = double.tryParse(val) ?? 0;
                                  setDialogState(() {
                                    jmlController.text = (usdVal * currentRate).toInt().toString();
                                    isFetchingKurs = false;
                                  });
                                } else {
                                  jmlController.clear();
                                }
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.compare_arrows, color: Colors.grey, size: 20),
                          ),
                          Expanded(
                            child: TextField(
                                controller: jmlController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: "IDR", prefixText: "Rp ")
                            ),
                          ),
                        ],
                      ),
                      if (isFetchingKurs) const LinearProgressIndicator(),
                      const SizedBox(height: 20),
                      // ... (Pilih Wallet & Kategori)
                      if (AppData.wallets.isNotEmpty) ...[
                        const Text("Pilih Wallet", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          children: List.generate(AppData.wallets.length, (index) => ChoiceChip(
                            label: Text(AppData.wallets[index].nama, style: const TextStyle(fontSize: 11)),
                            selected: selectedWalletIndex == index,
                            onSelected: (val) => setDialogState(() => selectedWalletIndex = index),
                          )),
                        ),
                      ],
                      if (jenis == "keluar") ...[
                        const SizedBox(height: 15),
                        const Text("Kategori", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          children: daftarKategori.map((kat) => ChoiceChip(
                            label: Text(kat, style: const TextStyle(fontSize: 11)),
                            selected: selectedKategori == kat,
                            onSelected: (val) => setDialogState(() => selectedKategori = kat),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () async {
                    int? jumlah = int.tryParse(jmlController.text);
                    if (jumlah != null && selectedWalletIndex != null) {
                      final newTransaksi = Transaksi(
                        keterangan: ketController.text,
                        jumlah: jumlah,
                        jenis: jenis,
                        tanggal: selectedDate,
                        walletNama: AppData.wallets[selectedWalletIndex!].nama,
                        kategori: jenis == "keluar" ? selectedKategori : "Pemasukan",
                      );

                      // Simpan ke Database
                      await DatabaseHelper.instance.insertTransaksi(newTransaksi);

                      // Tarik data terbaru untuk sinkronisasi list dan saldo
                      await _initData();

                      if (mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: jenis == "masuk" ? Colors.green : Colors.red),
                  child: const Text("Simpan", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter transaksi untuk ditampilkan di riwayat hari ini
    final filteredTransaksi = AppData.transaksi.where((t) {
      return t.tanggal.day == selectedDate.day &&
          t.tanggal.month == selectedDate.month &&
          t.tanggal.year == selectedDate.year;
    }).toList().reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Halo, Elga!", style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Row(
                          children: [
                            Text(DateFormat('EEEE, dd MMMM yyyy').format(selectedDate),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Action Buttons
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
              ),
              child: Row(
                children: [
                  Expanded(child: _quickActionButton(icon: Icons.add_circle, label: "Pemasukan", color: Colors.green, onTap: () => showInputDialog("masuk"))),
                  Expanded(child: _quickActionButton(icon: Icons.remove_circle, label: "Pengeluaran", color: Colors.red, onTap: () => showInputDialog("keluar"))),
                ],
              ),
            ),
          ),
          // List Riwayat
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Text("Riwayat Hari Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: filteredTransaksi.isEmpty
                ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Belum ada transaksi"))))
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final t = filteredTransaksi[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: Icon(t.jenis == "masuk" ? Icons.arrow_downward : Icons.arrow_upward, color: t.jenis == "masuk" ? Colors.green : Colors.red),
                      title: Text(t.keterangan),
                      subtitle: Text("${t.kategori} • ${t.walletNama}"),
                      trailing: Text("Rp ${NumberFormat.decimalPattern('id').format(t.jumlah)}", style: TextStyle(fontWeight: FontWeight.bold, color: t.jenis == "masuk" ? Colors.green : Colors.red)),
                    ),
                  );
                },
                childCount: filteredTransaksi.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}