import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'home_screen.dart';

class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    // Button tabhi active hoga jab naam ki length kam se kam 3 characters ho
    bool canSave = _nameController.text.trim().length >= 3 && !_isSaving;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Complete Profile"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // User piche na ja sake
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What should we call you?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 10),
            const Text("This name will be visible to your Buddies.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Enter your full name",
                prefixIcon: const Icon(Icons.person_outline, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: canSave ? () async {
                  setState(() { _isSaving = true; });
                  
                  // Database mein naam save karna
                  await DatabaseService().updateUserName(_nameController.text.trim());
                  
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save & Start Bonding", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}