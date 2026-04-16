import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../data/database_helper.dart';
import '../data/app_data.dart';

class ExportService {
  static Future<String> exportTransaksiToCSV() async {
    // 1. Ambil data dari database
    final List<Transaksi> listTransaksi = await DatabaseHelper.instance.fetchTransaksi();

    // 2. Buat header dan isi baris
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Keterangan", "Jumlah", "Jenis", "Tanggal", "Wallet", "Kategori"]);

    for (var t in listTransaksi) {
      List<dynamic> row = [];
      row.add(listTransaksi.indexOf(t) + 1);
      row.add(t.keterangan);
      row.add(t.jumlah);
      row.add(t.jenis);
      row.add(t.tanggal.toIso8601String());
      row.add(t.walletNama);
      row.add(t.kategori);
      rows.add(row);
    }

    // 3. Konversi ke String CSV
    String csvData = const ListToCsvConverter().convert(rows);

    // 4. Simpan ke folder dokumen HP
    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFile = "${directory.path}/laporan_danaku_${DateTime.now().millisecondsSinceEpoch}.csv";
    final File file = File(pathOfTheFile);

    await file.writeAsString(csvData);

    return pathOfTheFile;
  }
}