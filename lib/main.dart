import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  runApp(const CoutureApp());
}

class CoutureApp extends StatelessWidget {
  const CoutureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Couture',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
