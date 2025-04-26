import 'package:flutter/material.dart';
import 'package:safestep/pages/HistoryScreen.dart';
import 'package:safestep/pages/HomeScreen.dart';
import 'package:safestep/pages/SplashScreen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SafeStepApp());
}

class SafeStepApp extends StatelessWidget {
  const SafeStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeStep',
      theme: ThemeData.dark(),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
