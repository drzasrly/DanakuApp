import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as ex;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../data/database_helper.dart';
import '../data/app_data.dart';

class ExportService {
  /// Helper untuk membuat KPI Card di PDF
  static pw.Widget _buildPdfKpiCard(String title, String value, PdfColor color) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(color: PdfColors.grey600, fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(color: color, fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 1. Ekspor Data Transaksi ke CSV
  static Future<String> exportTransaksiToCSV() async {
    final List<Transaksi> listTransaksi = await DatabaseHelper.instance.fetchTransaksi();

    List<List<dynamic>> rows = [];
    rows.add(["No", "Keterangan", "Jumlah", "Jenis", "Tanggal", "Dompet", "Kategori"]);

    for (int i = 0; i < listTransaksi.length; i++) {
      final t = listTransaksi[i];
      final formattedJumlah = "Rp ${NumberFormat.decimalPattern('id').format(t.jumlah)}";
      final formattedTanggal = DateFormat('dd-MM-yyyy').format(t.tanggal);

      List<dynamic> row = [];
      row.add(i + 1);
      row.add(t.keterangan);
      row.add(formattedJumlah);
      row.add(t.jenis.toUpperCase());
      row.add(formattedTanggal);
      row.add(t.walletNama);
      row.add(t.kategori);
      rows.add(row);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFile = "${directory.path}/laporan_danaku_${DateTime.now().millisecondsSinceEpoch}.csv";
    final File file = File(pathOfTheFile);

    await file.writeAsString(csvData);
    return pathOfTheFile;
  }

  /// 2. Ekspor Data Transaksi ke Excel (.xlsx) dengan Header Rapi
  static Future<String> exportTransaksiToExcel() async {
    await initializeDateFormatting('id', null);
    final List<Transaksi> listTransaksi = await DatabaseHelper.instance.fetchTransaksi();

    // Hitung Ringkasan
    int totalPemasukan = 0;
    int totalPengeluaran = 0;
    for (var t in listTransaksi) {
      if (t.jenis.toLowerCase() == 'masuk' || t.jenis.toLowerCase() == 'pemasukan') {
        totalPemasukan += t.jumlah;
      } else {
        totalPengeluaran += t.jumlah;
      }
    }
    int saldoBersih = totalPemasukan - totalPengeluaran;

    var excel = ex.Excel.createExcel();
    String sheetName = "Laporan Keuangan";
    excel.rename("Sheet1", sheetName);
    ex.Sheet sheetObject = excel[sheetName];

    // 1. Judul Laporan & Metadata
    sheetObject.appendRow([ex.TextCellValue("LAPORAN TRANSAKSI KEUANGAN - DANAKUAPP")]);
    
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'id').format(DateTime.now());
    sheetObject.appendRow([ex.TextCellValue("Dicetak Pada: $dateStr WIB")]);
    
    final totalPemStr = "Rp ${NumberFormat.decimalPattern('id').format(totalPemasukan)}";
    final totalPengStr = "Rp ${NumberFormat.decimalPattern('id').format(totalPengeluaran)}";
    final saldoBersihStr = "Rp ${NumberFormat.decimalPattern('id').format(saldoBersih)}";
    
    sheetObject.appendRow([
      ex.TextCellValue("Ringkasan: Total Pemasukan: $totalPemStr | Total Pengeluaran: $totalPengStr | Saldo Bersih: $saldoBersihStr")
    ]);
    
    // Baris Kosong Pemisah
    sheetObject.appendRow([]);

    // 2. Buat Header Kolom Tabel yang Rapi
    List<ex.CellValue> headers = [
      ex.TextCellValue("No"),
      ex.TextCellValue("Keterangan"),
      ex.TextCellValue("Jumlah (IDR)"),
      ex.TextCellValue("Jenis"),
      ex.TextCellValue("Tanggal"),
      ex.TextCellValue("Dompet / Rekening"),
      ex.TextCellValue("Kategori"),
    ];
    sheetObject.appendRow(headers);

    // 3. Buat Baris Data
    for (int i = 0; i < listTransaksi.length; i++) {
      final t = listTransaksi[i];
      final formattedJumlah = "Rp ${NumberFormat.decimalPattern('id').format(t.jumlah)}";
      final formattedTanggal = DateFormat('dd-MM-yyyy').format(t.tanggal);

      sheetObject.appendRow([
        ex.IntCellValue(i + 1),
        ex.TextCellValue(t.keterangan),
        ex.TextCellValue(formattedJumlah),
        ex.TextCellValue(t.jenis.toUpperCase()),
        ex.TextCellValue(formattedTanggal),
        ex.TextCellValue(t.walletNama),
        ex.TextCellValue(t.kategori),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception("Gagal mengode berkas Excel");

    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFile = "${directory.path}/laporan_danaku_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    final File file = File(pathOfTheFile);

    await file.writeAsBytes(bytes);
    return pathOfTheFile;
  }

  /// 3. Ekspor Data Transaksi ke PDF (.pdf) Premium dengan Banner & KPI Card
  static Future<String> exportTransaksiToPDF() async {
    await initializeDateFormatting('id', null);
    final List<Transaksi> listTransaksi = await DatabaseHelper.instance.fetchTransaksi();

    // Hitung Ringkasan untuk KPI
    int totalPemasukan = 0;
    int totalPengeluaran = 0;
    for (var t in listTransaksi) {
      if (t.jenis.toLowerCase() == 'masuk' || t.jenis.toLowerCase() == 'pemasukan') {
        totalPemasukan += t.jumlah;
      } else {
        totalPengeluaran += t.jumlah;
      }
    }
    int saldoBersih = totalPemasukan - totalPengeluaran;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // 1. BANNER HEADER PREMIUM
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColors.teal800,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "DANAKUAPP - LAPORAN KEUANGAN TRANSAKSI",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Catatan Lengkap Arus Kas Masuk dan Keluar Pengguna",
                        style: pw.TextStyle(
                          color: PdfColors.teal100,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "WAKTU CETAK",
                        style: pw.TextStyle(color: PdfColors.teal100, fontSize: 7, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "${DateFormat('dd MMMM yyyy, HH:mm', 'id').format(DateTime.now())} WIB",
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 2. KARTU RINGKASAN FINANSIAL (KPI BLOCK)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfKpiCard("Total Transaksi", "${listTransaksi.length} Data", PdfColors.blue800),
                _buildPdfKpiCard("Total Pemasukan", "Rp ${NumberFormat.decimalPattern('id').format(totalPemasukan)}", PdfColors.green800),
                _buildPdfKpiCard("Total Pengeluaran", "Rp ${NumberFormat.decimalPattern('id').format(totalPengeluaran)}", PdfColors.red800),
                _buildPdfKpiCard("Saldo Bersih", "Rp ${NumberFormat.decimalPattern('id').format(saldoBersih)}", saldoBersih >= 0 ? PdfColors.teal800 : PdfColors.orange900),
              ],
            ),
            pw.SizedBox(height: 20),

            // 3. TABEL DATA TRANSAKSI SANGAT RAPI & ELEGAN
            pw.TableHelper.fromTextArray(
              headers: ["No", "Keterangan", "Jumlah", "Jenis", "Tanggal", "Dompet", "Kategori"],
              data: List<List<String>>.generate(listTransaksi.length, (index) {
                final t = listTransaksi[index];
                final formattedJumlah = "Rp ${NumberFormat.decimalPattern('id').format(t.jumlah)}";
                final formattedTanggal = DateFormat('dd-MM-yyyy').format(t.tanggal);

                return [
                  (index + 1).toString(),
                  t.keterangan,
                  formattedJumlah,
                  t.jenis.toUpperCase() == "MASUK" || t.jenis.toUpperCase() == "PEMASUKAN" ? "PEMASUKAN" : "PENGELUARAN",
                  formattedTanggal,
                  t.walletNama,
                  t.kategori,
                ];
              }),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.center,     // No (Center)
                2: pw.Alignment.centerRight, // Jumlah (Right - Standard Keuangan)
                3: pw.Alignment.center,     // Jenis (Center)
                4: pw.Alignment.center,     // Tanggal (Center)
              },
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFile = "${directory.path}/laporan_danaku_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final File file = File(pathOfTheFile);

    await file.writeAsBytes(bytes);
    return pathOfTheFile;
  }
}