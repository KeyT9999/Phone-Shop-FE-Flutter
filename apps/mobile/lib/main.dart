import 'package:flutter/material.dart';

import 'navigation/store_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PhoneStoreApp());
}

class PhoneStoreApp extends StatelessWidget {
  const PhoneStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DTC Phone Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const StoreShell(),
    );
  }
}
