import 'package:bonding_app/auth_wrapper.dart';
import 'package:bonding_app/screens/splash_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 1. Flutter Engine start
  await Firebase.initializeApp(); // 2. Firebase connect
  // await FirebaseAuth.instance.signOut();
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
        // 2026 Premium Indigo Theme (As specified by you)
        primaryColor: const Color(0xFF4B0082),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      
      // Flow: Pehle SplashScreen dikhega 2 second ke liye.
      // Uske baad SplashScreen khud Navigator.pushReplacement karke 
      // AuthWrapper ko bula lega.
      home: const SplashScreen(), 
    );
  }
}