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
  DateTime selectedDate = DateTime.now();
  List<Transaksi> transaksiBulanIni = [];
  String viewMode = "Total"; // Pengeluaran, Penghasilan, Total
  bool isCalendarView = true;
  bool _isObscured = false;

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
  }

  Future<void> _loadTransaksi() async {
    final allTransaksi = await DatabaseHelper.instance.fetchTransaksi();
    setState(() {
      transaksiBulanIni = allTransaksi.where((t) {
        return t.tanggal.month == selectedDate.month && t.tanggal.year == selectedDate.year;
      }).toList();
    });
  }

  void _nextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
      _loadTransaksi();
    });
  }

  void _prevMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
      _loadTransaksi();
    });
  }

  IconData _getCategoryIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'makan': return Icons.restaurant;
      case 'transport': return Icons.directions_car;
      case 'belanja': return Icons.shopping_cart;
      case 'tagihan': return Icons.receipt;
      case 'hiburan': return Icons.movie;
      default: return Icons.category;
    }
  }

  Color _getCategoryColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'makan': return Colors.orange;
      case 'transport': return Colors.blue;
      case 'belanja': return Colors.pink;
      case 'tagihan': return Colors.red;
      case 'hiburan': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Stack(
        children: [
          // Background Pink Gradient
          Container(
            height: 350,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF528F), Color(0xFFFF7A9F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.search, color: Colors.white, size: 28),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => isCalendarView = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isCalendarView ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.shopping_basket, color: !isCalendarView ? Colors.pink : Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text("Detail", style: TextStyle(color: !isCalendarView ? Colors.pink : Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setState(() => isCalendarView = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isCalendarView ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_month, color: isCalendarView ? Colors.blue : Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text("Kalender", style: TextStyle(color: isCalendarView ? Colors.pink : Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      "catatan mada",
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  // Horizontal Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        _topActionItem(Icons.person_pin_outlined, "catatan ...", true),
                        const SizedBox(width: 25),
                        _topActionItem(Icons.add, "Baru Buku", false),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),

                  // Conditional View
                  if (isCalendarView) ...[
                    _buildCalendarCard(),
                    const SizedBox(height: 20),
                    _buildBottomTotals(),
                  ] else ...[
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    _buildTransactionList(),
                  ],
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topActionItem(IconData icon, String label, bool isSelected) {
    return Column(
      children: [
        Container(
          width: 65, height: 65,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withAlpha(80) : Colors.transparent,
            border: isSelected ? null : Border.all(color: Colors.white.withAlpha(150), width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: isSelected ? Colors.white : Colors.tealAccent, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildSummaryCard() {
    int totalIncome = transaksiBulanIni.where((t) => t.jenis == "masuk" || t.jenis == "pemasukan").fold(0, (sum, t) => sum + t.jumlah);
    int totalExpense = transaksiBulanIni.where((t) => t.jenis == "keluar" || t.jenis == "pengeluaran").fold(0, (sum, t) => sum + t.jumlah);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('MMMM yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              IconButton(
                icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _isObscured ? "Rp •••••••" : "Rp${NumberFormat.decimalPattern('id').format(totalIncome - totalExpense)}",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    _isObscured ? "Rp •••••••" : "Rp${NumberFormat.decimalPattern('id').format(totalIncome)}",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.arrow_circle_down, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      const Text("Penghasilan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    _isObscured ? "Rp •••••••" : "Rp${NumberFormat.decimalPattern('id').format(totalExpense)}",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.arrow_circle_up, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      const Text("Pengeluaran", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    Map<String, List<Transaksi>> grouped = {};
    for (var t in transaksiBulanIni) {
      String key = DateFormat('yyyy-MM-dd').format(t.tanggal);
      grouped[key] ??= [];
      grouped[key]!.add(t);
    }
    var keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    if (keys.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Belum ada transaksi")));

    return Column(
      children: keys.map((dateKey) {
        var list = grouped[dateKey]!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('E, dd/MM').format(DateTime.parse(dateKey)), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const Icon(Icons.arrow_drop_down, color: Colors.pink, size: 20),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...list.map((t) {
                final catData = [...AppData.pengeluaranCategories, ...AppData.pemasukanCategories]
                    .firstWhere((c) => c.nama == t.kategori, orElse: () => TransactionCategory(nama: t.kategori, icon: Icons.category));
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: catData.imagePath != null ? Colors.pink.withAlpha(25) : _getCategoryColor(t.kategori).withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: catData.imagePath != null 
                        ? Image.asset(catData.imagePath!, width: 24, height: 24)
                        : Icon(_getCategoryIcon(t.kategori), color: _getCategoryColor(t.kategori)),
                  ),
                  title: Text(t.keterangan, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(t.walletNama, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Text(
                    "${(t.jenis.toLowerCase() == 'masuk' || t.jenis.toLowerCase() == 'pemasukan') ? '+' : '-'}Rp${NumberFormat.decimalPattern('id').format(t.jumlah)}",
                    style: TextStyle(
                      color: (t.jenis.toLowerCase() == "masuk" || t.jenis.toLowerCase() == "pemasukan") ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 15, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: Colors.pink), onPressed: _prevMonth),
              Text(DateFormat('MMMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(20)),
                    child: const Text("Month", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right, color: Colors.pink), onPressed: _nextMonth),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"].map((day) {
              return SizedBox(width: 40, child: Center(child: Text(day, style: TextStyle(color: day == "Min" || day == "Sab" ? Colors.red.shade300 : Colors.grey, fontSize: 13))));
            }).toList(),
          ),
          const SizedBox(height: 10),
          _buildCalendarGrid(),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: ["Pengeluaran", "Penghasilan", "Total"].map((mode) {
                bool isSelected = viewMode == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => viewMode = mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: isSelected ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 5)] : null,
                      ),
                      child: Center(child: Text(mode, style: TextStyle(color: isSelected ? Colors.pink : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7;
    List<Widget> dayWidgets = [];
    for (int i = 0; i < firstWeekday; i++) dayWidgets.add(const SizedBox(height: 60));
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
      int income = transaksiBulanIni.where((t) => t.tanggal.day == day && (t.jenis == "masuk" || t.jenis == "pemasukan")).fold(0, (sum, t) => sum + t.jumlah);
      int expense = transaksiBulanIni.where((t) => t.tanggal.day == day && (t.jenis == "keluar" || t.jenis == "pengeluaran")).fold(0, (sum, t) => sum + t.jumlah);
      dayWidgets.add(
        Container(
          height: 65,
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: isToday ? Colors.pink : Colors.transparent, shape: BoxShape.circle),
                child: Center(child: Text("$day", style: TextStyle(color: isToday ? Colors.white : (date.weekday == 7 || date.weekday == 6 ? Colors.red.shade400 : Colors.black87), fontWeight: isToday ? FontWeight.bold : FontWeight.normal))),
              ),
              const SizedBox(height: 2),
              if (viewMode == "Total") ...[
                if (income - expense != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: (income - expense) > 0 ? Colors.green.shade400 : Colors.red.shade400, borderRadius: BorderRadius.circular(4)),
                    child: Text("${(income - expense) > 0 ? '' : '-'}${( (income - expense).abs() / 1000).toStringAsFixed(0)} rb", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
              ] else if (viewMode == "Penghasilan") ...[
                if (income > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: BorderRadius.circular(4)),
                    child: Text("${(income / 1000).toStringAsFixed(0)} rb", style: const TextStyle(color: Colors.white, fontSize: 8)),
                  ),
              ] else if (viewMode == "Pengeluaran") ...[
                if (expense > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(4)),
                    child: Text("-${(expense / 1000).toStringAsFixed(0)} rb", style: const TextStyle(color: Colors.white, fontSize: 8)),
                  ),
              ],
            ],
          ),
        ),
      );
    }
    return GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: dayWidgets);
  }

  Widget _buildBottomTotals() {
    int totalIncome = transaksiBulanIni.where((t) => t.jenis == "masuk" || t.jenis == "pemasukan").fold(0, (sum, t) => sum + t.jumlah);
    int totalExpense = transaksiBulanIni.where((t) => t.jenis == "keluar" || t.jenis == "pengeluaran").fold(0, (sum, t) => sum + t.jumlah);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _bottomTotalItem("Rp${NumberFormat.decimalPattern('id').format(totalIncome - totalExpense)}", "Total"),
          _bottomTotalItem("Rp${NumberFormat.decimalPattern('id').format(totalIncome)}", "Penghasilan"),
          _bottomTotalItem("Rp${NumberFormat.decimalPattern('id').format(totalExpense)}", "Pengeluaran"),
        ],
      ),
    );
  }

  Widget _bottomTotalItem(String amount, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}