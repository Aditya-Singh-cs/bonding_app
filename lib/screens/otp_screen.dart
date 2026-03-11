import 'dart:async'; // Timer ke liye zaroori hai
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart'; // Database entry ke liye
import 'home_screen.dart';
import 'name_entry_screen.dart'; // NAYA IMPORT: Name Entry ke liye

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
  
  // Timer related variables
  late Timer _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // Timer shuru karne ka logic
  void _startTimer() {
    _canResend = false;
    _secondsRemaining = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer.cancel();
        }
      });
    });
  }

  // OTP Resend karne ka logic
  void _resendOtp() {
    AuthService().sendOTP(widget.phoneNumber, (newVerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Resent Successfully!")),
      );
      _startTimer(); // Timer fir se shuru
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Memory leak se bachne ke liye timer band karo
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CHANGE: Button logic variable
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
              
              // OTP Input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                // CHANGE: Re-build UI on every character change
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "000000", 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              
              // Timer and Resend Row
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
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  // CHANGE: Button enabled only if isOtpReady is true
                  onPressed: isOtpReady ? () async {
                    setState(() { _isVerifying = true; });
                    try {
                      // 1. OTP Verify Karo
                      await AuthService().verifyOTP(
                        widget.verificationId,
                        _otpController.text.trim(),
                      );

                      // 2. Database mein user setup karo (5 min balance)
                      await DatabaseService().setupNewUser();

                      // 3. SMART NAVIGATION: Check if Name is set
                      bool nameExists = await DatabaseService().isNameSet();

                      if (mounted) {
                        if (nameExists) {
                          // Purana User -> Seedha Home
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                            (route) => false,
                          );
                        } else {
                          // Naya User -> Name Entry Page
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const NameEntryScreen()),
                            (route) => false,
                          );
                        }
                      }
                    } catch (e) {
                      setState(() { _isVerifying = false; });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid OTP! Please try again.")),
                      );
                    }
                  } : null, // Hard disable when validation fails
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