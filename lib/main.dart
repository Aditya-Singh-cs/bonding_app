import 'package:bonding_app/screens/login_screen.dart';
import 'package:bonding_app/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bonding_app/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 1. Engine start
  await Firebase.initializeApp(); // 2. Firebase connect
  runApp(const BondingApp()); // 3. App launch
}

class BondingApp extends StatelessWidget {
  const BondingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bonding',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 2026 Premium Indigo Theme
        primaryColor: const Color(0xFF4B0082),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      // home: const LoginScreen(),
      home: const SplashScreen(),
    );
  }
}
