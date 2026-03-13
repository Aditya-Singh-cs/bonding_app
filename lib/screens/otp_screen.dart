import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // NAYA IMPORT
import 'package:firebase_auth/firebase_auth.dart'; // NAYA IMPORT
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'home_screen.dart';
import 'name_entry_screen.dart';
import 'buddy_dashboard.dart'; // NAYA IMPORT

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  late Timer _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _canResend = false;
    _secondsRemaining = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _canResend = true;
            _timer.cancel();
          }
        });
      }
    });
  }

  void _resendOtp() {
    AuthService().sendOTP(widget.phoneNumber, (newVerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Resent Successfully!")),
      );
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isOtpReady = _otpController.text.length == 6 && !_isVerifying;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              Text(
                "Verify +91 ${widget.phoneNumber}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter the 6-digit code sent to your phone",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "000000",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _canResend ? "Didn't receive code? " : "Resend in $_secondsRemaining seconds",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  if (_canResend)
                    TextButton(
                      onPressed: _resendOtp,
                      child: const Text("Resend OTP", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isOtpReady ? () async {
                    setState(() { _isVerifying = true; });
                    try {
                      // 1. OTP Verify Karo
                      await AuthService().verifyOTP(
                        widget.verificationId,
                        _otpController.text.trim(),
                      );

                      // --- NAYA SMART NAVIGATION LOGIC ---
                      String phone = "+91${widget.phoneNumber.trim()}";

                      // 2. Sabse pehle Buddy check karo
                      var buddyQuery = await FirebaseFirestore.instance
                          .collection('buddies')
                          .where('phoneNumber', isEqualTo: phone)
                          .get();

                      if (mounted) {
                        if (buddyQuery.docs.isNotEmpty) {
                          // BANDA BUDDY HAI!
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const BuddyDashboard()),
                            (route) => false,
                          );
                        } else {
                          // BANDA NORMAL USER HAI
                          await DatabaseService().setupNewUser();
                          bool nameExists = await DatabaseService().isNameSet();

                          if (nameExists) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                              (route) => false,
                            );
                          } else {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const NameEntryScreen()),
                              (route) => false,
                            );
                          }
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() { _isVerifying = false; });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invalid OTP! Please try again.")),
                        );
                      }
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isVerifying 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Verify & Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}