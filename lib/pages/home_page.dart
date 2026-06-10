import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import 'transaction_input_page.dart';
import 'manage_wallet_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  List<Transaksi> transaksiBulanIni = [];
  String viewMode = "Total"; // Pengeluaran, Penghasilan, Total
  bool isCalendarView = false;
  bool _isObscured = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final allTransaksi = await DatabaseHelper.instance.fetchTransaksi();
    final allWallets = await DatabaseHelper.instance.fetchWallets();
    setState(() {
      AppData.wallets = allWallets;
      transaksiBulanIni = allTransaksi.where((t) {
        return t.tanggal.month == selectedDate.month && t.tanggal.year == selectedDate.year;
      }).toList();
    });
  }

  void _nextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
      _loadData();
    });
  }

  void _prevMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
      _loadData();
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

  void _showSwitchBookDialog() async {
    final books = await DatabaseHelper.instance.fetchBooks();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Pilih Buku", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...books.map((b) => ListTile(
              leading: const Icon(Icons.book, color: Colors.pink),
              title: Text(b.nama, style: TextStyle(fontWeight: AppData.activeBookId == b.id ? FontWeight.bold : FontWeight.normal)),
              trailing: AppData.activeBookId == b.id ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () {
                setState(() {
                  AppData.activeBookId = b.id!;
                  AppData.activeBookName = b.nama;
                });
                _loadData();
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        );
      }
    );
  }

  void _createNewBook() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Buku Baru"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Nama Buku (misal: Tabungan Elga)"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final newId = await DatabaseHelper.instance.insertBook(nameController.text.trim());
                setState(() {
                  AppData.activeBookId = newId;
                  AppData.activeBookName = nameController.text.trim();
                });
                // Initialize default empty wallet for new book
                await DatabaseHelper.instance.saveWallets([
                  Wallet(nama: "Utama", saldo: 0, jenis: "Akun Virtual", icon: Icons.account_balance_wallet)
                ]);
                _loadData();
                Navigator.pop(context);
              }
            },
            child: const Text("Buat", style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Stack(
        children: [
          // Background Pink Gradient - Responsive Height
          Container(
            height: screenSize.height * 0.4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF528F), Color(0xFFFF7A9F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
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
                            Flexible(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildViewToggleButton(
                                    icon: Icons.shopping_basket,
                                    label: "Detail",
                                    isActive: !isCalendarView,
                                    activeColor: Colors.pink,
                                    onTap: () => setState(() => isCalendarView = false),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildViewToggleButton(
                                    icon: Icons.calendar_month,
                                    label: "Kalender",
                                    isActive: isCalendarView,
                                    activeColor: Colors.blue,
                                    onTap: () => setState(() => isCalendarView = true),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: InkWell(
                          onTap: _showSwitchBookDialog,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  AppData.activeBookName,
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontSize: isTablet ? 40 : 32, 
                                    fontWeight: FontWeight.bold
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 30),
                            ],
                          ),
                        ),
                      ),
                      
                      // Horizontal Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            _topActionItem(Icons.person_pin_outlined, AppData.activeBookName.split(' ').first, true),
                            const SizedBox(width: 25),
                            _topActionItem(Icons.add, "Baru Buku", false, onTap: _createNewBook),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withAlpha(50),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.white, size: 18),
            const SizedBox(width: 5),
            Text(
              label, 
              style: TextStyle(
                color: isActive ? activeColor : Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 12,
              )
            ),
          ],
        ),
      ),
    );
  }


  Widget _topActionItem(IconData icon, String label, bool isSelected, {VoidCallback? onTap}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = MediaQuery.of(context).size.width > 600 ? 80 : 65;
        return GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: size, height: size,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withAlpha(80) : Colors.transparent,
                  border: isSelected ? null : Border.all(color: Colors.white.withAlpha(150), width: 1.5),
                  borderRadius: BorderRadius.circular(size * 0.3),
                ),
                child: Icon(icon, color: isSelected ? Colors.white : Colors.tealAccent, size: size * 0.45),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        );
      }
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isObscured ? "Rp •••••••" : "Rp${NumberFormat.decimalPattern('id').format(totalIncome - totalExpense)}",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _isObscured ? "Rp •••••" : "Rp${NumberFormat.decimalPattern('id').format(totalIncome)}",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_circle_down, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            const Text("Masuk", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(height: 30, width: 1, color: Colors.black12),
                  Expanded(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _isObscured ? "Rp •••••" : "Rp${NumberFormat.decimalPattern('id').format(totalExpense)}",
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_circle_up, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            const Text("Keluar", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }
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
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: const Icon(Icons.edit, color: Colors.blue),
                            title: const Text("Edit Transaksi"),
                            onTap: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionInputPage(
                                    initialJenis: t.jenis.toLowerCase() == 'masuk' ? 'masuk' : 'keluar',
                                    initialTransaksi: t,
                                  ),
                                ),
                              );
                              if (result == true) _loadData();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text("Hapus Transaksi"),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Hapus"),
                                  content: const Text("Yakin ingin menghapus transaksi ini?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await DatabaseHelper.instance.deleteTransaksi(t);
                                        _loadData();
                                      },
                                      child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
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
                  title: Text(t.keterangan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(t.walletNama, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Text(
                    "${(t.jenis.toLowerCase() == 'masuk' || t.jenis.toLowerCase() == 'pemasukan') ? '+' : '-'}Rp${NumberFormat.decimalPattern('id').format(t.jumlah)}",
                    style: TextStyle(
                      color: (t.jenis.toLowerCase() == "masuk" || t.jenis.toLowerCase() == "pemasukan") ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
              Flexible(child: Text(DateFormat('MMMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(20)),
                    child: const Text("Month", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
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
              return Expanded(child: Center(child: Text(day, style: TextStyle(color: day == "Min" || day == "Sab" ? Colors.red.shade300 : Colors.grey, fontSize: 12))));
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
                      child: Center(child: Text(mode, style: TextStyle(color: isSelected ? Colors.pink : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 11))),
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
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
      int income = transaksiBulanIni.where((t) => t.tanggal.day == day && (t.jenis == "masuk" || t.jenis == "pemasukan")).fold(0, (sum, t) => sum + t.jumlah);
      int expense = transaksiBulanIni.where((t) => t.tanggal.day == day && (t.jenis == "keluar" || t.jenis == "pengeluaran")).fold(0, (sum, t) => sum + t.jumlah);
      dayWidgets.add(
        LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: isToday ? Colors.pink : Colors.transparent, shape: BoxShape.circle),
                  child: Center(child: Text("$day", style: TextStyle(color: isToday ? Colors.white : (date.weekday == 7 || date.weekday == 6 ? Colors.red.shade400 : Colors.black87), fontWeight: isToday ? FontWeight.bold : FontWeight.normal, fontSize: 12))),
                ),
                const SizedBox(height: 2),
                if (viewMode == "Total") ...[
                  if (income - expense != 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: (income - expense) > 0 ? Colors.green.shade400 : Colors.red.shade400, borderRadius: BorderRadius.circular(4)),
                        child: Text("${(income - expense) > 0 ? '' : '-'}${( (income - expense).abs() / 1000).toStringAsFixed(0)}k", style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ] else if (viewMode == "Penghasilan") ...[
                  if (income > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: BorderRadius.circular(4)),
                        child: Text("${(income / 1000).toStringAsFixed(0)}k", style: const TextStyle(color: Colors.white, fontSize: 7)),
                      ),
                    ),
                ] else if (viewMode == "Pengeluaran") ...[
                  if (expense > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(4)),
                        child: Text("-${(expense / 1000).toStringAsFixed(0)}k", style: const TextStyle(color: Colors.white, fontSize: 7)),
                      ),
                    ),
                ],
              ],
            );
          }
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7, 
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      childAspectRatio: 0.85,
      children: dayWidgets
    );
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