import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Isse date format karenge

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Call History"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Current user ki sub-collection se data le rahe hain
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('call_history')
            .orderBy('timestamp', descending: true) // Latest calls upar
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No call records found. Start a call now!"),
            );
          }

          final calls = snapshot.data!.docs;

          return ListView.builder(
            itemCount: calls.length,
            itemBuilder: (context, index) {
              var callData = calls[index].data() as Map<String, dynamic>;
              
              // Duration format: seconds to mm:ss
              int duration = callData['duration'] ?? 0;
              String formattedDuration = "${(duration ~/ 60)}m ${duration % 60}s";

              // Date format
              DateTime? date = (callData['timestamp'] as Timestamp?)?.toDate();
              String formattedDate = date != null 
                  ? DateFormat('dd MMM, hh:mm a').format(date) 
                  : "Just now";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigoAccent,
                    child: Icon(Icons.call_received, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    callData['buddyName'] ?? "Buddy",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(formattedDate),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedDuration,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      const Text("Duration", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}