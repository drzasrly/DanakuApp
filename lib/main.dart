import 'package:flutter/material.dart';
import 'pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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