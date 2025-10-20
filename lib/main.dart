import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ Gerado pelo FlutterFire

import 'screens/map_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/report_screen.dart';

void main() async {
  // ✅ Inicializar Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('✅ Firebase inicializado com sucesso!');

  runApp(TrafficApp());
}

class TrafficApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Trânsito - Colatina',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => MapScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/report': (context) => ReportScreen(),
      },
      initialRoute: '/',
    );
  }
}
