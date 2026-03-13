import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/buddy_dashboard.dart';
import 'screens/name_entry_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final String? phone = snapshot.data!.phoneNumber;
        final String uid = snapshot.data!.uid;

        return FutureBuilder<Map<String, dynamic>?>(
          future: _checkUserRole(phone, uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
              );
            }

            final data = roleSnapshot.data;

            // CASE A: Buddy identified
            if (data != null && data['role'] == 'buddy') {
              debugPrint("SUCCESS: Buddy Identified");
              return const BuddyDashboard();
            }

            // CASE B: Existing User
            if (data != null && data['role'] == 'user' && data['name'] != null) {
              debugPrint("SUCCESS: Existing User Identified");
              return const HomeScreen();
            }

            // CASE C: Agar dono nahi mile toh hi 'New User' par bhejo
            debugPrint("LOG: No role found, sending to Name Entry");
            return const NameEntryScreen();
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _checkUserRole(String? phone, String uid) async {
    try {
      // 1. Ek chhota sa delay (500ms) taaki Firebase details sync ho jayein
      await Future.delayed(const Duration(milliseconds: 500));
      
      String? checkPhone = phone ?? FirebaseAuth.instance.currentUser?.phoneNumber;
      
      if (checkPhone == null) return null;

      // 2. Buddy Check (Strict check)
      var buddyQuery = await FirebaseFirestore.instance
          .collection('buddies')
          .where('phoneNumber', isEqualTo: checkPhone.trim())
          .get();

      if (buddyQuery.docs.isNotEmpty) {
        var d = buddyQuery.docs.first.data();
        d['role'] = 'buddy';
        return d;
      }

      // 3. User Check (UID se fetch karo kyuki ye hamesha unique hai)
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        var d = userDoc.data();
        if (d != null) {
          d['role'] = 'user';
          return d;
        }
      }
    } catch (e) {
      debugPrint("Error in Role Check: $e");
    }
    return null;
  }
}