import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BuddyDashboard extends StatefulWidget {
  const BuddyDashboard({super.key});

  @override
  State<BuddyDashboard> createState() => _BuddyDashboardState();
}

class _BuddyDashboardState extends State<BuddyDashboard> {
  bool _isOnline = false;
  String buddyName = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadBuddyData();
  }

  // Dashboard load hote hi current status check karo
  void _loadBuddyData() async {
    String phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? "";
    var query = await FirebaseFirestore.instance
        .collection('buddies')
        .where('phoneNumber', isEqualTo: phone)
        .get();

    if (query.docs.isNotEmpty) {
      setState(() {
        buddyName = query.docs.first['name'];
        _isOnline = query.docs.first['isOnline'] ?? false;
      });
    }
  }

  // Status badalne ka logic
  void _toggleStatus(bool value) async {
    String phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? "";
    var query = await FirebaseFirestore.instance
        .collection('buddies')
        .where('phoneNumber', isEqualTo: phone)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({'isOnline': value});
      setState(() => _isOnline = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, $buddyName"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Status Card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: _isOnline ? Colors.green.shade50 : Colors.red.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _isOnline ? Colors.green : Colors.red,
                  child: const Icon(Icons.power_settings_new, color: Colors.white),
                ),
                title: Text(_isOnline ? "You are ONLINE" : "You are OFFLINE", 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isOnline ? "Users can now call you" : "Call requests disabled"),
                trailing: Switch(
                  value: _isOnline,
                  onChanged: _toggleStatus,
                  activeColor: Colors.green,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Stats Row
            Row(
              children: [
                _buildStatTile("Today's Earnings", "₹0.00", Icons.currency_rupee),
                const SizedBox(width: 15),
                _buildStatTile("Minutes Spent", "0 min", Icons.timer),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}