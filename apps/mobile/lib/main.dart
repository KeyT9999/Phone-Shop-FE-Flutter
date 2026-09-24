import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PhoneStoreApp());
}

class PhoneStoreApp extends StatelessWidget {
  const PhoneStoreApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DTC Phone Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Xanh navy hiện đại sang trọng
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
