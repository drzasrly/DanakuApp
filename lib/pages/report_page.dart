import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as Math;
import 'dart:ui' as ui;
import '../data/app_data.dart';
import '../data/database_helper.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _viewMode = 0; // 0: Pengeluaran, 1: Penghasilan, 2: Kategori, 3: Akun, 4: Tren/Aset
  String _groupBy = "Kategori"; // "Kategori" or "Akun"
  DateTime _selectedMonth = DateTime.now();
  List<Transaksi> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await DatabaseHelper.instance.fetchTransaksi();
    setState(() {
      _transactions = all.where((t) => t.tanggal.month == _selectedMonth.month && t.tanggal.year == _selectedMonth.year).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        elevation: 0,
        leading: const Icon(Icons.menu_book, color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Analisis", style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            Text(DateFormat('M/yyyy').format(_selectedMonth), style: const TextStyle(color: Colors.white, fontSize: 16)),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
      body: Column(
        children: [
          // View Mode Toggle Bar
          Container(
            color: const Color(0xFFFF528F),
            padding: const EdgeInsets.only(bottom: 15, left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildModeIcon(0, Icons.shopping_cart, "Pengeluaran"),
                _buildModeIcon(1, Icons.savings, "Penghasilan"),
                _buildModeIcon(2, Icons.fact_check, "Kategori"),
                _buildModeIcon(3, Icons.account_balance, "Akun"),
                _buildModeIcon(4, Icons.account_balance_wallet, "Aset"),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildSubToggle(),
                  const SizedBox(height: 20),
                  _buildMainContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeIcon(int index, IconData icon, String label) {
    bool isActive = _viewMode == index;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.pink : Colors.white70, size: 20),
            if (isActive) ...[
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 12)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSubToggle() {
    if (_viewMode >= 4) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Oleh $_groupBy", style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 13)),
              const Icon(Icons.keyboard_arrow_down, color: Colors.pink, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_viewMode == 4) return _buildTrendView();
    
    // Grouping logic
    final isExpense = _viewMode == 0 || _viewMode == 2 || _viewMode == 3;
    final filtered = _transactions.where((t) => isExpense ? (t.jenis == "keluar" || t.jenis == "pengeluaran") : t.jenis == "masuk").toList();
    
    Map<String, int> grouped = {};
    int total = 0;
    for (var t in filtered) {
      String key = _viewMode == 3 ? t.walletNama : t.kategori;
      grouped[key] = (grouped[key] ?? 0) + t.jumlah;
      total += t.jumlah;
    }

    if (total == 0) return const Center(child: Padding(padding: EdgeInsets.all(50), child: Text("Tidak ada data", style: TextStyle(color: Colors.grey))));

    return Column(
      children: [
        // Donut Chart
        SizedBox(
          height: 320,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(220, 220),
                painter: DonutChartPainter(grouped: grouped, total: total),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isExpense ? "Pengeluaran" : "Penghasilan", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  Text("Rp${NumberFormat.decimalPattern('id').format(total)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              )
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        const Divider(height: 1),
        
        // List Breakdown
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            String key = grouped.keys.elementAt(index);
            int value = grouped[key]!;
            double percent = (value / total) * 100;
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.pink.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long, color: Colors.pink, size: 24),
              ),
              title: Text(key, style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${percent.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(width: 20),
                  Text("Rp${NumberFormat.decimalPattern('id').format(value)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildTrendView() {
    return Column(
      children: [
        // Line Chart (Real Trend)
        Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.all(15),
          height: 350,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF528F), Color(0xFFFF7A9F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   _buildSmallTag("Tren", true),
                   const SizedBox(width: 10),
                   _buildSmallTag("Aset", false),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendDot(Colors.green, "Penghasilan"),
                  const SizedBox(width: 20),
                  _buildLegendDot(Colors.orange, "Pengeluaran"),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: TrendChartPainter(transactions: _transactions),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Table Data
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.grey.shade100),
                child: const Row(
                  children: [
                    Expanded(child: Text("  Tanggal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(child: Text("Penghasilan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(child: Text("Pengeluaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(child: Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
              ),
              ..._buildDailyTableRows(),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 2, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  List<Widget> _buildDailyTableRows() {
    Map<String, Map<String, int>> daily = {};
    for (var t in _transactions) {
      String date = DateFormat('dd/M').format(t.tanggal);
      if (!daily.containsKey(date)) daily[date] = {"in": 0, "out": 0};
      if (t.jenis == "masuk") {
        daily[date]!["in"] = (daily[date]!["in"] ?? 0) + t.jumlah;
      } else {
        daily[date]!["out"] = (daily[date]!["out"] ?? 0) + t.jumlah;
      }
    }

    final sortedKeys = daily.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return sortedKeys.map((date) {
      int inc = daily[date]!["in"]!;
      int exp = daily[date]!["out"]!;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(
          children: [
            Expanded(child: Text("  $date", style: const TextStyle(fontSize: 12))),
            Expanded(child: Text("Rp${NumberFormat.decimalPattern('id').format(inc)}", style: const TextStyle(color: Colors.green, fontSize: 11))),
            Expanded(child: Text("Rp${NumberFormat.decimalPattern('id').format(exp)}", style: const TextStyle(color: Colors.red, fontSize: 11))),
            Expanded(child: Text("Rp${NumberFormat.decimalPattern('id').format(inc - exp)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSmallTag(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: isActive ? Colors.white : Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(15)),
      child: Text(label, style: TextStyle(color: isActive ? Colors.pink : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final Map<String, int> grouped;
  final int total;

  DonutChartPainter({required this.grouped, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 40;
    const strokeWidth = 50.0;
    
    double startAngle = -1.5708;
    final List<Color> colors = [Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.pink, Colors.teal, Colors.indigo];
    
    int i = 0;
    grouped.forEach((key, value) {
      double sweepAngle = (value / total) * 6.28319;
      if (sweepAngle < 0.05) sweepAngle = 0.05; // Min visibility

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
      
      // Label placement
      double midAngle = startAngle + sweepAngle / 2;
      double lx = center.dx + (radius + 60) * 1.1 * Math.cos(midAngle);
      double ly = center.dy + (radius + 60) * 1.1 * Math.sin(midAngle);
      
      // Draw small circle for icon/label
      final labelPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      final shadowPaint = Paint()..color = Colors.black.withAlpha(30)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
      
      canvas.drawCircle(Offset(lx, ly), 22, shadowPaint);
      canvas.drawCircle(Offset(lx, ly), 20, labelPaint);
      
      // Percentage text
      final textPainter = TextPainter(
        text: TextSpan(text: "${((value/total)*100).toInt()}%", style: TextStyle(color: colors[i % colors.length], fontWeight: FontWeight.bold, fontSize: 10)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(lx - textPainter.width/2, ly - textPainter.height/2));

      startAngle += sweepAngle;
      i++;
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class TrendChartPainter extends CustomPainter {
  final List<Transaksi> transactions;

  TrendChartPainter({required this.transactions});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.white.withAlpha(30)..strokeWidth = 1;
    for (int i = 0; i <= 5; i++) {
      double y = size.height / 5 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (transactions.isEmpty) return;

    // Daily aggregation
    Map<int, double> dailyIn = {};
    Map<int, double> dailyOut = {};
    for (var t in transactions) {
      int day = t.tanggal.day;
      if (t.jenis == "masuk") dailyIn[day] = (dailyIn[day] ?? 0) + t.jumlah;
      else dailyOut[day] = (dailyOut[day] ?? 0) + t.jumlah;
    }

    double maxVal = 0;
    for (var v in dailyIn.values) if (v > maxVal) maxVal = v;
    for (var v in dailyOut.values) if (v > maxVal) maxVal = v;
    if (maxVal == 0) maxVal = 1;

    // Draw Lines
    _drawLine(canvas, size, dailyIn, Colors.green, maxVal);
    _drawLine(canvas, size, dailyOut, Colors.orange, maxVal);
  }

  void _drawLine(Canvas canvas, Size size, Map<int, double> data, Color color, double maxVal) {
    if (data.isEmpty) return;
    
    final path = Path();
    double xStep = size.width / 30; // Max days
    
    bool first = true;
    for (int i = 1; i <= 30; i++) {
      double val = data[i] ?? 0;
      double x = (i-1) * xStep;
      double y = size.height - (val / maxVal * size.height * 0.8);
      
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    // Shaded Area
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = color.withAlpha(30)..style = PaintingStyle.fill);

    // Line
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
