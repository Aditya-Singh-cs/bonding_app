import 'dart:async';
import 'package:bonding_app/services/database_service.dart'; // DatabaseService import karo
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'name_entry_screen.dart'; // Name Entry Screen import karo

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  _navigateToNext() async {
    // 2 second ka branding wait
    await Future.delayed(const Duration(milliseconds: 2000));

    User? user = FirebaseAuth.instance.currentUser;

    if (mounted) {
      if (user != null) {
        // --- NAYA SMART LOGIC ---
        // Check karo ki user ka naam database mein hai ya nahi
        bool hasName = await DatabaseService().isNameSet();

        if (mounted) {
          if (hasName) {
            // User logged in hai AUR naam bhi set hai -> Home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            // User logged in hai lekin naam nahi dala -> Name Entry
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const NameEntryScreen()),
            );
          }
        }
      } else {
        // User logged in nahi hai -> Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.handshake_rounded, size: 80, color: Colors.indigo),
            ),
            const SizedBox(height: 20),
            const Text(
              "Bonding",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}