import 'package:bonding_app/screens/otp_screen.dart';
import 'package:bonding_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this for input control

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  // --- VALIDATION LOGIC ---
  bool _isPhoneValid(String phone) {
    // 1. Exactly 10 digits check
    if (phone.length != 10) return false;
    // 2. Starts with 6, 7, 8, or 9 (Indian numbers)
    if (!RegExp(r'^[6-9]').hasMatch(phone)) return false;
    // 3. Reject identical numbers like 0000000000 or 1111111111
    if (RegExp(r'^(\d)\1{9}$').hasMatch(phone)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Har character type hone par ye check karega ki button neela hona chahiye ya nahi
    bool canProceed = _isPhoneValid(_phoneController.text.trim()) && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 100),
              Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.handshake_rounded,
                    size: 80,
                    color: Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                "Welcome to Bonding",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Enter your phone number to start making friends.",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_isLoading,
                maxLength: 10, // UI limit
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Sirf 0-9
                ],
                onChanged: (val) {
                  setState(() {}); // Button state update karne ke liye
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.phone_iphone,
                    color: Colors.indigo,
                  ),
                  prefixText: "+91 ", // India code hamesha rahega
                  hintText: "XXXXXXXXXX", // Placeholder changed as you said
                  counterText: "", // Hide 0/10
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  // Button logic: Enabled only if canProceed is true
                  onPressed: canProceed
                      ? () {
                          String phone = _phoneController.text.trim();
                          setState(() {
                            _isLoading = true;
                          });

                          AuthService().sendOTP(phone, (verId) {
                            setState(() {
                              _isLoading = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("OTP Sent Successfully!"),
                              ),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OTPScreen(
                                  verificationId: verId,
                                  phoneNumber: phone,
                                ),
                              ),
                            );
                          });
                        }
                      : null, // Hard Disable (Grey button)
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: canProceed ? 5 : 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Get OTP",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "By continuing, you agree to our Terms & Conditions",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}