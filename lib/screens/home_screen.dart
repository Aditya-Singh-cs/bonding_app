// import 'package:bonding_app/screens/profile_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'call_screen.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         title: const Text('Bonding 🤝', style: TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.indigo,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.account_circle),
//             onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
//           ),
//         ],
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // --- BALANCE SECTION ---
//           StreamBuilder<DocumentSnapshot>(
//             stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
//               var userData = snapshot.data!.data() as Map<String, dynamic>;
//               int totalSeconds = userData['balanceSeconds'] ?? 0;
//               return _buildBalanceCard(totalSeconds);
//             },
//           ),

//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
//             child: Text("Available Buddies", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
//           ),

//           // --- BUDDIES LIST ---
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance.collection('buddies').where('isOnline', isEqualTo: true).snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No buddies online."));

//                 return ListView.builder(
//                   padding: const EdgeInsets.all(10),
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     var buddy = snapshot.data!.docs[index].data() as Map<String, dynamic>;
//                     return _buildBuddyCard(context, buddy, uid);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBuddyCard(BuildContext context, Map<String, dynamic> buddy, String uid) {
//     return Card(
//       elevation: 3,
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Padding(
//         padding: const EdgeInsets.all(15.0),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(radius: 30, backgroundImage: NetworkImage(buddy['imageUrl'] ?? '')),
//                 const SizedBox(width: 15),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(buddy['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                       Text(buddy['bio'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.star, color: Colors.amber, size: 18),
//                       Text(" ${buddy['rating'] ?? 0.0}", style: const TextStyle(fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const Divider(height: 30),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildActionColumn(context, Icons.message, "Text", buddy['textPrice'] ?? 0, uid, buddy['name']),
//                 _buildActionColumn(context, Icons.call, "Call", buddy['callPrice'] ?? 0, uid, buddy['name']),
//                 _buildActionIconVideo(context, Icons.videocam, "Video", buddy['videoPrice'] ?? 0, uid, buddy['name']),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionColumn(BuildContext context, IconData icon, String label, int price, String uid, String name) {
//     return InkWell(
//       onTap: () => _handleCallStart(context, uid, name), // Restriction Removed
//       child: Column(
//         children: [
//           Icon(icon, color: Colors.indigo, size: 28),
//           const SizedBox(height: 4),
//           Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
//           Text("₹$price/min", style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   // Video ke liye alag function agar baad m video screen banani ho
//   Widget _buildActionIconVideo(BuildContext context, IconData icon, String label, int price, String uid, String name) {
//      return Column(
//         children: [
//           Icon(icon, color: Colors.grey, size: 28), // Abhi ke liye grey/disabled look
//           const SizedBox(height: 4),
//           Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
//           Text("₹$price/min", style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
//         ],
//       );
//   }

//   // --- LOGIC: Zero Balance Protection ---
//   void _handleCallStart(BuildContext context, String uid, String buddyName) async {
//     // Fresh balance fetch karo
//     var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
//     int currentBalance = userDoc.data()?['balanceSeconds'] ?? 0;

//     // Check: Agar balance ekdum 0 hai, tabhi roko
//     if (currentBalance <= 0) {
//       _showRechargeAlert(context);
//     } else {
//       // Agar 1 second bhi hai, toh call start hone do
//       Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(buddyName: buddyName)));
//     }
//   }

//   void _showRechargeAlert(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Balance Exhausted"),
//         content: const Text("Please recharge your wallet to continue talking to buddies."),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
//           ElevatedButton(onPressed: () { 
//             Navigator.pop(context);
//             // Navigator to RechargeScreen logic here
//           }, child: const Text("Recharge Now")),
//         ],
//       ),
//     );
//   }

//   Widget _buildBalanceCard(int totalSeconds) {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(colors: [Colors.indigo, Colors.indigoAccent]),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text("Your Talk Time", style: TextStyle(color: Colors.white70)),
//               Text("${totalSeconds ~/ 60} min ${totalSeconds % 60} sec", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
//             ],
//           ),
//           const Icon(Icons.account_balance_wallet, color: Colors.white, size: 35),
//         ],
//       ),
//     );
//   }
// }
import 'package:bonding_app/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'call_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Bonding 🤝', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- STEP 1: Smart Balance Switch (Trial vs Wallet) ---
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              
              // Naye fields fetch ho rahi hain
              int trial = userData['trialSeconds'] ?? 0;
              int wallet = userData['walletBalanceInPaise'] ?? 0;
              bool isTrialUsed = userData['isTrialUsed'] ?? false;

              return _buildBalanceCard(trial, wallet, isTrialUsed);
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text("Available Buddies", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),

          // --- BUDDIES LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('buddies').where('isOnline', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No buddies online."));

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var buddy = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return _buildBuddyCard(context, buddy, uid);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuddyCard(BuildContext context, Map<String, dynamic> buddy, String uid) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 30, backgroundImage: NetworkImage(buddy['imageUrl'] ?? 'https://via.placeholder.com/150')),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(buddy['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(buddy['bio'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(" ${buddy['rating'] ?? 0.0}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (buddy['canText'] ?? true)
                  _buildActionColumn(context, Icons.message, "Text", buddy['textPrice'] ?? 0, uid, buddy['name']),
                
                if (buddy['canCall'] ?? true)
                  _buildActionColumn(context, Icons.call, "Call", buddy['callPrice'] ?? 0, uid, buddy['name']),
                
                if (buddy['canVideo'] ?? true)
                  _buildActionColumn(context, Icons.videocam, "Video", buddy['videoPrice'] ?? 0, uid, buddy['name']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionColumn(BuildContext context, IconData icon, String label, int price, String uid, String name) {
    return InkWell(
      onTap: () => _handleActionStart(context, uid, name, price, label),
      child: Column(
        children: [
          Icon(icon, color: Colors.indigo, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text("₹$price/min", style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- STEP 2: Logic for Trial + Wallet Check ---
  void _handleActionStart(BuildContext context, String uid, String buddyName, int price, String type) async {
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    var userData = userDoc.data() as Map<String, dynamic>;
    
    int trial = userData['trialSeconds'] ?? 0;
    int wallet = userData['walletBalanceInPaise'] ?? 0;
    bool isTrialUsed = userData['isTrialUsed'] ?? false;

    // Check: Trial bacha hai (aur used nahi hua) YA wallet mein paise hain?
    if ((trial <= 0 || isTrialUsed) && wallet <= 0) {
      _showRechargeAlert(context);
    } else {
      if (type == "Text") {
        print("Chat logic pending...");
      } else {
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => CallScreen(
              buddyName: buddyName, 
              pricePerMin: price, 
              callType: type,
            )
          )
        );
      }
    }
  }

  void _showRechargeAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Zero Balance"),
        content: const Text("Aapka Trial aur Wallet dono khali hain. Recharge karein?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () { Navigator.pop(context); }, child: const Text("Recharge Now")),
        ],
      ),
    );
  }

  // --- STEP 3: FIXED Master Switch Logic ---
  Widget _buildBalanceCard(int trial, int wallet, bool isTrialUsed) {
    // FIX: Trial tabhi dikhao jab trial > 0 ho AUR isTrialUsed FALSE ho.
    // Agar isTrialUsed true ho gaya, toh bhale hi trialSeconds mein kuch bhi ho, hamesha wallet dikhao.
    bool showTrial = trial > 0 && !isTrialUsed;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.indigo, Colors.indigoAccent]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                showTrial ? "Free Trial Minutes" : "Wallet Balance", 
                style: const TextStyle(color: Colors.white70)
              ),
              Text(
                showTrial 
                    ? "${trial ~/ 60} min ${trial % 60} sec" 
                    : "₹${(wallet / 100).toStringAsFixed(2)}", 
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 35),
        ],
      ),
    );
  }
}