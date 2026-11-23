import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  runApp(const Root());
}
