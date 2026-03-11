import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class CallScreen extends StatefulWidget {
  final String buddyName;
  final int pricePerMin; 
  final String callType; 

  const CallScreen({
    super.key,
    required this.buddyName,
    required this.pricePerMin,
    required this.callType,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _timer;
  int _totalSecondsAvailable = 0; 
  int _secondsSpent = 0;
  bool _isLoading = true;
  bool _isTrialCall = false; 

  @override
  void initState() {
    super.initState();
    _initCallLogic();
  }

  // 1. Logic: Firebase se Krishna Chahar wala data check karna
  // void _initCallLogic() async {
  //   final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    
  //   try {
  //     // Seedha Firestore se fetch kar rahe hain taaki koi function ka locha na rahe
  //     var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      
  //     if (userDoc.exists && mounted) {
  //       var data = userDoc.data() as Map<String, dynamic>;
        
  //       // Tere fields: trialSeconds aur walletBalance
  //       int trial = data['trialSeconds'] ?? 0;
  //       int wallet = data['walletBalance'] ?? 0;

  //       setState(() {
  //         if (trial > 0) {
  //           // Agar trialSeconds (299) bache hain
  //           _isTrialCall = true;
  //           _totalSecondsAvailable = trial;
  //         } else if (wallet > 0) {
  //           // Agar trial 0 hai par wallet mein paise hain
  //           _isTrialCall = false;
  //           // Math: (Rupees / Rate) * 60
  //           _totalSecondsAvailable = ((wallet / widget.pricePerMin) * 60).floor();
  //         } else {
  //           _totalSecondsAvailable = 0;
  //         }
  //         _isLoading = false;
  //       });

  //       if (_totalSecondsAvailable > 0) {
  //         _startTimer();
  //       } else {
  //         _showPayDialog();
  //       }
  //     }
  //   } catch (e) {
  //     print("Error initialization: $e");
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }
  // CallScreen ki _initCallLogic mein ye change karo:

void _initCallLogic() async {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
  var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  
  if (userDoc.exists && mounted) {
    var data = userDoc.data() as Map<String, dynamic>;
    int trial = data['trialSeconds'] ?? 0;
    int wallet = data['walletBalance'] ?? 0;
    bool isTrialUsed = data['isTrialUsed'] ?? false; // Flag check kiya

    setState(() {
      // FIX: Trial tabhi chale jab Seconds > 0 hon AUR isTrialUsed FALSE ho
      if (trial > 0 && !isTrialUsed) {
        _isTrialCall = true;
        _totalSecondsAvailable = trial;
      } else {
        // Warna hamesha Paid Call maano
        _isTrialCall = false;
        _totalSecondsAvailable = ((wallet / widget.pricePerMin) * 60).floor();
      }
      _isLoading = false;
    });

    if (_totalSecondsAvailable > 0) {
      _startTimer();
    } else {
      _showPayDialog();
    }
  }
}

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsSpent < _totalSecondsAvailable) {
        if (mounted) {
          setState(() {
            _secondsSpent++;
          });
        }
      } else {
        _timer?.cancel();
        _showPayDialog();
      }
    });
  }

  // 2. Call End: Database ko update karna
  Future<void> _endCall() async {
    _timer?.cancel();

    if (_secondsSpent > 0) {
      // DatabaseService mein decreaseBalance call karega (Isme seconds spent bhej rahe hain)
      await DatabaseService().decreaseBalance(_secondsSpent, pricePerMin:widget.pricePerMin);

      await DatabaseService().saveCallRecord(
        buddyName: widget.buddyName,
        durationInSeconds: _secondsSpent,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      _showPostCallRating(); 
    }
  }

  void _showPostCallRating() {
    print("Rating triggered for ${widget.buddyName}");
  }

  void _showPayDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Samay Samapt!"),
        content: Text(
          _isTrialCall 
          ? "Aapka Free Trial (Minutes) khatam ho gaye hain." 
          : "Aapka Wallet Balance khali ho gaya hai.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endCall();
            },
            child: const Text("Ok, End Call", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endCall();
              // TODO: Navigate to Recharge
            },
            child: const Text("Recharge Now"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int remainingSeconds = _totalSecondsAvailable - _secondsSpent;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.indigo,
                        child: Icon(
                          widget.callType == "Video" ? Icons.videocam : Icons.person,
                          size: 70, color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.buddyName,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isTrialCall ? "FREE TRIAL CALL" : "PAID CALL",
                        style: TextStyle(color: _isTrialCall ? Colors.amber : Colors.green, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 50),

                      // Timer Display
                      Text(
                        "${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w200),
                      ),

                      const SizedBox(height: 100),

                      FloatingActionButton.large(
                        onPressed: _endCall,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.call_end, size: 40, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (!_isTrialCall)
                  Positioned(
                    top: 50,
                    right: 20,
                    child: Chip(
                      label: Text("₹${widget.pricePerMin}/min"),
                      backgroundColor: Colors.white10,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
    );
  }
}