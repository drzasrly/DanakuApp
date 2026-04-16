import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import '../services/exchange_service.dart'; // Pastikan path service sudah benar

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

  Future<void> _initData() async {
    final listT = await DatabaseHelper.instance.fetchTransaksi();
    final listW = await DatabaseHelper.instance.fetchWallets();

    setState(() {
      AppData.transaksi = listT;
      AppData.wallets = listW;

      if (AppData.wallets.isEmpty) {
        AppData.wallets.add(Wallet(nama: "Utama", saldo: 0));
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

    TextEditingController ketController = TextEditingController();
    TextEditingController jmlController = TextEditingController();
    TextEditingController usdController = TextEditingController();

    int? selectedWalletIndex = AppData.wallets.isNotEmpty ? 0 : null;
    String selectedKategori = "Lainnya";
    double currentRate = 15800.0; // Nilai default jika API gagal
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

                      // --- INPUT MULTI-CURRENCY (KURS) DENGAN DATABASE OFFLINE ---
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: usdController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: "Dalam USD",
                                  prefixText: "\$ ",
                                  labelStyle: TextStyle(fontSize: 12)
                              ),
                              onChanged: (val) async {
                                if (val.isNotEmpty) {
                                  setDialogState(() => isFetchingKurs = true);
                                  try {
                                    // 1. Coba ambil dari API
                                    final data = await _exchangeService.fetchRates();
                                    currentRate = data['rates']['IDR'].toDouble();

                                    // 2. Berhasil? Simpan kurs terbaru ke database settings
                                    await DatabaseHelper.instance.saveLastRate(currentRate);

                                    double usdVal = double.tryParse(val) ?? 0;
                                    setDialogState(() {
                                      jmlController.text = (usdVal * currentRate).toInt().toString();
                                      isFetchingKurs = false;
                                    });
                                  } catch (e) {
                                    // 3. Gagal/Offline? Ambil kurs terakhir yang tersimpan di database
                                    double savedRate = await DatabaseHelper.instance.getLastRate();
                                    double usdVal = double.tryParse(val) ?? 0;
                                    setDialogState(() {
                                      currentRate = savedRate;
                                      jmlController.text = (usdVal * currentRate).toInt().toString();
                                      isFetchingKurs = false;
                                    });
                                  }
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
                                decoration: const InputDecoration(
                                    labelText: "Dalam IDR",
                                    prefixText: "Rp ",
                                    labelStyle: TextStyle(fontSize: 12)
                                )
                            ),
                          ),
                        ],
                      ),

                      if (isFetchingKurs)
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),

                      if (usdController.text.isNotEmpty && !isFetchingKurs)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            "* Estimasi Kurs: 1 USD = Rp ${NumberFormat.decimalPattern('id').format(currentRate.toInt())}",
                            style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),

                      const SizedBox(height: 20),
                      if (AppData.wallets.isNotEmpty) ...[
                        const Text("Pilih Wallet", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          children: List.generate(AppData.wallets.length, (index) => ChoiceChip(
                            label: Text(AppData.wallets[index].nama, style: const TextStyle(fontSize: 11)),
                            selected: selectedWalletIndex == index,
                            selectedColor: Colors.orange.withOpacity(0.2),
                            onSelected: (val) => setDialogState(() => selectedWalletIndex = index),
                          )),
                        ),
                        const SizedBox(height: 15),
                      ],
                      if (jenis == "keluar") ...[
                        const Text("Kategori", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          children: daftarKategori.map((kat) => ChoiceChip(
                            label: Text(kat, style: const TextStyle(fontSize: 11)),
                            selected: selectedKategori == kat,
                            selectedColor: Colors.red.withOpacity(0.1),
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
                      await DatabaseHelper.instance.insertTransaksi(newTransaksi);
                      setState(() {
                        if (jenis == "keluar") {
                          AppData.wallets[selectedWalletIndex!].saldo -= jumlah;
                        } else {
                          AppData.wallets[selectedWalletIndex!].saldo += jumlah;
                        }
                        AppData.transaksi.add(newTransaksi);
                      });
                      await DatabaseHelper.instance.saveWallets(AppData.wallets);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: jenis == "masuk" ? Colors.green : Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
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
    final filteredTransaksi = AppData.transaksi.where((t) {
      return t.tanggal.day == selectedDate.day &&
          t.tanggal.month == selectedDate.month &&
          t.tanggal.year == selectedDate.year;
    }).toList().reversed.toList();

    String formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(selectedDate);
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 800 : screenWidth),
          child: CustomScrollView(
            slivers: [
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
                                Text(formattedDate, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                const Icon(Icons.arrow_drop_down, color: Colors.black54),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.history_rounded, color: Color(0xFFB87C00)),
                          onPressed: () {}
                      )
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _quickActionButton(
                          icon: Icons.add_circle_outline,
                          label: "Pemasukan",
                          color: Colors.green,
                          onTap: () => showInputDialog("masuk"),
                        ),
                      ),
                      Container(height: 30, width: 1, color: Colors.grey[200]),
                      Expanded(
                        child: _quickActionButton(
                          icon: Icons.remove_circle_outline,
                          label: "Pengeluaran",
                          color: Colors.red,
                          onTap: () => showInputDialog("keluar"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 5),
                  child: Text("Riwayat Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: filteredTransaksi.isEmpty
                    ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("Tidak ada transaksi pada tanggal ini", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                )
                    : SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final t = filteredTransaksi[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: t.jenis == "masuk" ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            child: Icon(
                                t.jenis == "masuk" ? Icons.call_received_rounded : Icons.call_made_rounded,
                                color: t.jenis == "masuk" ? Colors.green : Colors.red,
                                size: 18
                            ),
                          ),
                          title: Text(t.keterangan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text("${t.kategori} • ${t.walletNama}", style: const TextStyle(fontSize: 12)),
                          trailing: Text(
                            "${t.jenis == "masuk" ? "+" : "-"} Rp ${NumberFormat.decimalPattern('id').format(t.jumlah)}",
                            style: TextStyle(
                                color: t.jenis == "masuk" ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredTransaksi.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}