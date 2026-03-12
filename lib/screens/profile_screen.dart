// import 'package:flutter/material.dart';
// import '../models/buddy_model.dart'; // Global timer ke liye

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("My Profile"),
//         backgroundColor: Colors.indigo,
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 30),
//           const Center(
//             child: CircleAvatar(
//               radius: 50,
//               backgroundColor: Colors.indigo,
//               child: Icon(Icons.person, size: 50, color: Colors.white),
//             ),
//           ),
//           const SizedBox(height: 15),
//           const Text(
//             "Aditya Singh", // Tera naam
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 30),

//           // Wallet/Balance Card
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               elevation: 4,
//               child: ListTile(
//                 leading: const Icon(
//                   Icons.account_balance_wallet,
//                   color: Colors.indigo,
//                   size: 30,
//                 ),
//                 title: const Text("Remaining Time"),
//                 subtitle: const Text("Your free trial balance"),
//                 trailing: Text(
//                   "${(globalSecondsRemaining ~/ 60)} min",
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),
//           ListTile(
//             leading: const Icon(Icons.history),
//             title: const Text("Call History"),
//             onTap: () {},
//           ),
//           ListTile(
//             leading: const Icon(Icons.settings),
//             title: const Text("Settings"),
//             onTap: () {},
//           ),
//           const Spacer(),
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text(
//                 "Logout",
//                 style: TextStyle(
//                   color: Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:bonding_app/screens/call_history_screen.dart';
import 'package:bonding_app/screens/login_screen.dart';
import 'package:bonding_app/screens/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // --- LOGOUT LOGIC (INTACT) ---
  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); 
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? "New User";
          
          // --- STEP 1: Fetching New Fields ---
          int trial = userData['trialSeconds'] ?? 0;
          int walletPaise = userData['walletBalanceInPaise'] ?? 0;
          bool isTrialUsed = userData['isTrialUsed'] ?? false;

          // Master Switch: Decision Making
          bool showTrial = trial > 0 && !isTrialUsed;

          return Column(
            children: [
              const SizedBox(height: 30),
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // --- STEP 2: Smart Wallet Card ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  child: ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.indigo,
                      size: 30,
                    ),
                    // Phase ke hisaab se Title badlega
                    title: Text(showTrial ? "Free Trial Time" : "Wallet Balance"),
                    // Phase ke hisaab se Subtitle badlega
                    subtitle: Text(showTrial ? "Your free gift minutes" : "Available funds"),
                    
                    // --- DYNAMIC BALANCE (Minutes or ₹) ---
                    trailing: Text(
                      showTrial 
                        ? "${trial ~/ 60}m ${trial % 60}s" 
                        : "₹${(walletPaise / 100).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text("Call History"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CallHistoryScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextButton(
                  onPressed: () => _handleLogout(context),
                  child: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}