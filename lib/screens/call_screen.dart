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

  // FIXED: Logic for fetching data and calculating time
  void _initCallLogic() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      
      if (userDoc.exists && mounted) {
        var data = userDoc.data() as Map<String, dynamic>;
        
        int trial = data['trialSeconds'] ?? 0;
        int walletInPaise = data['walletBalanceInPaise'] ?? 0;
        bool isTrialUsed = data['isTrialUsed'] ?? false;

        // DEBUG: Terminal mein check kar ki kya value aa rahi hai
        print("DEBUG: Trial Seconds: $trial, Wallet Paise: $walletInPaise, Used: $isTrialUsed");

        setState(() {
          // Check: Agar trial bacha hai AUR used nahi hua
          if (trial > 0 && !isTrialUsed) {
            _isTrialCall = true;
            _totalSecondsAvailable = trial;
          } 
          // Check: Warna wallet balance check karo
          else if (walletInPaise > 0) {
            _isTrialCall = false;
            // Precision Math: (Paise / (Rate * 100 / 60))
            double paisePerSec = (widget.pricePerMin * 100) / 60;
            _totalSecondsAvailable = (walletInPaise / paisePerSec).floor();
          } 
          else {
            _isTrialCall = false;
            _totalSecondsAvailable = 0;
          }
          _isLoading = false;
        });

        print("DEBUG: Total Seconds Available for this call: $_totalSecondsAvailable");

        if (_totalSecondsAvailable > 0) {
          _startTimer();
        } else {
          _showPayDialog();
        }
      }
    } catch (e) {
      print("Error initialization: $e");
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _endCall() async {
    _timer?.cancel();

    if (_secondsSpent > 0) {
      // Named parameter use kar rahe hain: pricePerMin
      await DatabaseService().decreaseBalance(_secondsSpent, pricePerMin: widget.pricePerMin);

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
        title: const Text("Balance Exhausted"),
        content: Text(
          _isTrialCall 
          ? "Aapka Free Trial khatam ho gaya hai." 
          : "Aapka Wallet Balance khali ho gaya hai.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endCall();
            },
            child: const Text("End Call", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endCall();
              // TODO: Navigate to Recharge Screen
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