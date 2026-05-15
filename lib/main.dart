import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // Inisialisasi sqflite untuk Web (Chrome, Edge)
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    // Inisialisasi sqflite untuk Windows & Linux (Desktop)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const DanakuApp());
}

class DanakuApp extends StatelessWidget {
  const DanakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Danaku App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Hapus Center dan SizedBox width: 400 agar aplikasi memenuhi layar
      home: const MainPage(),
    );
  }
}