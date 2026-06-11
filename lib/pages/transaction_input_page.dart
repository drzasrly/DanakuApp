import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import 'manage_category_page.dart';
import 'package:intl/intl.dart';
import '../services/exchange_service.dart';

class TransactionInputPage extends StatefulWidget {
  final String initialJenis;
  final Transaksi? initialTransaksi;

  const TransactionInputPage({super.key, required this.initialJenis, this.initialTransaksi});

  @override
  State<TransactionInputPage> createState() => _TransactionInputPageState();
}

class _TransactionInputPageState extends State<TransactionInputPage> {
  late String jenis;
  TransactionCategory? selectedCategory;
  String nominal = "0";
  TextEditingController keteranganController = TextEditingController();
  List<TransactionCategory> categories = [];
  DateTime selectedDate = DateTime.now();
  
  String selectedCurrency = "IDR";
  double usdToIdr = 16000.0;
  bool isLoadingRate = false;
  Wallet? selectedWallet;

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaksi != null) {
      final t = widget.initialTransaksi!;
      jenis = t.jenis.toLowerCase() == 'masuk' || t.jenis.toLowerCase() == 'pemasukan' ? 'masuk' : 'keluar';
      nominal = t.jumlah.toString();
      keteranganController.text = t.keterangan;
      selectedDate = t.tanggal;
      selectedWallet = AppData.wallets.firstWhere((w) => w.nama == t.walletNama, orElse: () => AppData.wallets.first);
      // Category will be selected after _loadCategories
    } else {
      jenis = widget.initialJenis;
      if (AppData.wallets.isNotEmpty) {
        selectedWallet = AppData.wallets.first;
      }
    }
    _loadCategories();
    _loadLastRate();
  }

  Future<void> _loadLastRate() async {
    final rate = await DatabaseHelper.instance.getLastRate();
    if (rate > 0) {
      setState(() => usdToIdr = rate);
    }
  }

  Future<void> _showWalletPicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Pilih Dompet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            ...AppData.wallets.map((w) => ListTile(
              leading: Icon(w.icon, color: Colors.pink),
              title: Text(w.nama),
              trailing: Text("Rp${NumberFormat.decimalPattern('id').format(w.saldo)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () {
                setState(() => selectedWallet = w);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchRate() async {
    setState(() => isLoadingRate = true);
    try {
      final data = await ExchangeService().fetchRates();
      if (data.containsKey('rates') && data['rates'].containsKey('IDR')) {
        double newRate = data['rates']['IDR'].toDouble();
        setState(() => usdToIdr = newRate);
        await DatabaseHelper.instance.saveLastRate(newRate);
      }
    } catch (e) {
      debugPrint("Gagal fetch rate: $e");
    } finally {
      setState(() => isLoadingRate = false);
    }
  }

  Future<void> _loadCategories() async {
    final list = await DatabaseHelper.instance.fetchCategories(jenis);
    setState(() {
      categories = list;
      if (widget.initialTransaksi != null) {
        selectedCategory = categories.firstWhere(
          (c) => c.nama == widget.initialTransaksi!.kategori,
          orElse: () => categories.isNotEmpty ? categories.first : TransactionCategory(nama: "Unknown", icon: Icons.category),
        );
      } else if (categories.isNotEmpty) {
        selectedCategory = categories.first;
      } else {
        selectedCategory = null;
      }
    });
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pink,
              onPrimary: Colors.white,
              onSurface: Colors.pink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.pink,
                onPrimary: Colors.white,
                onSurface: Colors.pink,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _onNumpadTap(String value) {
    setState(() {
      if (value == "DEL") {
        if (nominal.length > 1) {
          nominal = nominal.substring(0, nominal.length - 1);
        } else {
          nominal = "0";
        }
      } else if (value == ".") {
        if (!nominal.contains(".")) {
          nominal += ".";
        }
      } else {
        if (nominal == "0") {
          nominal = value;
        } else {
          if (nominal.length < 15) {
            nominal += value;
          }
        }
      }
    });
  }

  Future<void> _saveTransaction() async {
    double? parsedAmount = double.tryParse(nominal);
    double baseAmount = parsedAmount ?? 0;
    int jumlah = selectedCurrency == "USD" ? (baseAmount * usdToIdr).toInt() : baseAmount.toInt();

    if (jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nominal harus lebih dari 0")));
      return;
    }
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih kategori terlebih dahulu")));
      return;
    }
    if (selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih dompet terlebih dahulu")));
      return;
    }

    final newTransaksi = Transaksi(
      id: widget.initialTransaksi?.id,
      keterangan: keteranganController.text.isEmpty ? selectedCategory!.nama : keteranganController.text,
      jumlah: jumlah,
      jenis: jenis,
      tanggal: selectedDate,
      walletNama: selectedWallet!.nama,
      kategori: selectedCategory!.nama,
    );

    try {
      if (widget.initialTransaksi != null) {
        await DatabaseHelper.instance.updateTransaksi(widget.initialTransaksi!, newTransaksi);
      } else {
        await DatabaseHelper.instance.insertTransaksi(newTransaksi);
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan ke database!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    double? parsedAmount = double.tryParse(nominal);
    double converted = selectedCurrency == "USD" ? (parsedAmount ?? 0) * usdToIdr : (parsedAmount ?? 0);
    final screenSize = MediaQuery.of(context).size;
    final isShortScreen = screenSize.height < 700;
    final availableHeight = screenSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: SizedBox(
                height: availableHeight,
                child: Column(
                  children: [
                      // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.pink, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                      
                      // Toggle Switch
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(child: _buildTypeToggle("keluar", "Keluar", Icons.arrow_circle_up)),
                              Flexible(child: _buildTypeToggle("masuk", "Masuk", Icons.arrow_circle_down)),
                            ],
                          ),
                        ),
                      ),
                      
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.pink, size: 26),
                        onPressed: _saveTransaction,
                      ),
                    ],
                  ),
                ),

                if (!isShortScreen) const SizedBox(height: 10),

                // Category Grid - Adaptive columns
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = (constraints.maxWidth / 80).floor().clamp(3, 8);
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 15,
                        ),
                        itemCount: categories.length + 1,
                        itemBuilder: (context, index) {
                          if (index == categories.length) {
                            return GestureDetector(
                              onTap: () async {
                                 await Navigator.push(context, MaterialPageRoute(builder: (context) => ManageCategoryPage(jenis: jenis)));
                                 _loadCategories();
                              },
                              child: _buildCategoryItem(null, "Manage", Icons.settings_rounded, false, null),
                            );
                          }

                          final cat = categories[index];
                          return GestureDetector(
                            onTap: () => setState(() => selectedCategory = cat),
                            child: _buildCategoryItem(cat.imagePath, cat.nama, cat.icon, selectedCategory == cat, null),
                          );
                        },
                      );
                    }
                  ),
                ),

                // Numpad Area
                Container(
                  decoration: BoxDecoration(
                    color: Colors.pink.shade400,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  padding: EdgeInsets.fromLTRB(15, isShortScreen ? 10 : 20, 15, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Input Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        child: Row(
                          children: [
                            Icon(selectedWallet?.icon ?? Icons.wallet, color: Colors.green, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(selectedWallet?.nama ?? "Pilih Dompet", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  TextField(
                                    controller: keteranganController,
                                    decoration: const InputDecoration(hintText: "Nota", border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Currency Selector & Nominal
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selectedCurrency == "USD") ...[
                                      if (isLoadingRate) const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1)),
                                      Text(" (1\$ = ${usdToIdr.toInt()}) ", style: const TextStyle(fontSize: 8, color: Colors.grey)),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.refresh, size: 10, color: Colors.blue),
                                        onPressed: _fetchRate,
                                      ),
                                    ],
                                    const SizedBox(width: 5),
                                    GestureDetector(
                                      onTap: () => setState(() => selectedCurrency = selectedCurrency == "IDR" ? "USD" : "IDR"),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(5)),
                                        child: Text(selectedCurrency, style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 9)),
                                      ),
                                    ),
                                  ],
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    nominal,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (selectedCurrency == "USD")
                                  Text("≈ Rp${NumberFormat.decimalPattern('id').format(converted.toInt())}", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildNumpad(),
                    ],
                  ),
                )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(String type, String label, IconData icon) {
    bool isActive = jenis == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          jenis = type;
          _loadCategories();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(color: isActive ? Colors.pink : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : Colors.grey),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String? imagePath, String nama, IconData? icon, bool isSelected, Color? color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double iconSize = constraints.maxWidth * 0.4;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.pink.shade50 : Colors.transparent,
                border: Border.all(color: isSelected ? Colors.pink : Colors.transparent, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: imagePath != null
                  ? Image.asset(imagePath, width: iconSize, height: iconSize)
                  : Icon(icon, color: isSelected ? Colors.pink : Colors.grey.shade600, size: iconSize),
            ),
            const SizedBox(height: 4),
            Text(nama, style: TextStyle(color: isSelected ? Colors.pink : Colors.black87, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        );
      }
    );
  }

  Widget _buildNumpad() {
    bool isToday = DateFormat('yyyy-MM-dd').format(selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    String dateLabel = isToday ? "TODAY" : DateFormat('dd/MM HH:mm').format(selectedDate);
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: _buildNumpadButton(dateLabel, isAction: true, isDate: true)),
            Expanded(child: _buildNumpadButton("", icon: Icons.account_balance_wallet, isAction: true, iconColor: Colors.pink)),
            Expanded(child: _buildNumpadButton("", icon: Icons.check_circle_outline, isAction: true, iconColor: Colors.pink)),
          ],
        ),
        _buildNumpadRow(["x", "7", "8", "9"]),
        _buildNumpadRow(["/", "4", "5", "6"]),
        _buildNumpadRow(["-", "1", "2", "3"]),
        Row(
          children: [
            Expanded(child: _buildNumpadButton("+", isOperator: true)),
            Expanded(child: _buildNumpadButton(".")),
            Expanded(child: _buildNumpadButton("0")),
            Expanded(child: _buildNumpadButton("DEL", isOperator: true, icon: Icons.backspace)),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> labels) {
    return Row(
      children: labels.map((l) => Expanded(child: _buildNumpadButton(l, isOperator: l == "x" || l == "/" || l == "-" || l == "+"))).toList(),
    );
  }

  Widget _buildNumpadButton(String label, {bool isOperator = false, bool isAction = false, bool isDate = false, IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: () {
          if (isDate) {
            _selectDateTime();
          } else if (label == "" && icon == Icons.account_balance_wallet) _showWalletPicker();
          else if (label == "" && (icon == Icons.check_circle_outline || icon == Icons.check_box)) _saveTransaction();
          else if (label == "DEL" || icon == Icons.backspace) _onNumpadTap("DEL");
          else if (label.isNotEmpty) _onNumpadTap(label);
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(color: isAction ? Colors.pink.shade100 : (isOperator ? Colors.white.withAlpha(75) : Colors.white), borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1, offset: Offset(0, 1))]),
          alignment: Alignment.center,
          child: icon != null ? Icon(icon, color: iconColor ?? Colors.pink.shade700) : Text(label, style: TextStyle(fontSize: isDate ? 13 : 20, fontWeight: FontWeight.bold, color: isAction ? Colors.pink.shade900 : Colors.black87)),
        ),
      ),
    );
  }
}
