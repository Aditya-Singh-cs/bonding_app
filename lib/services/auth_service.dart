import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int? _resendToken; // Resend ke liye token store karenge

  // Phone number par OTP bhejna
  Future<void> sendOTP(String phoneNumber, Function(String) onCodeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: "+91$phoneNumber",
      forceResendingToken: _resendToken, // Agli baar ye use hoga
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Error: ${e.message}");
      },
      codeSent: (String verId, int? resendToken) {
        _resendToken = resendToken; // Token save kar lo
        onCodeSent(verId);
      },
      codeAutoRetrievalTimeout: (String verId) {},
    );
  }
  // Future<void> sendOTP(String phoneNumber, Function(String) onCodeSent) async {
  //   await _auth.verifyPhoneNumber(
  //     phoneNumber: "+91$phoneNumber",
  //     verificationCompleted: (PhoneAuthCredential credential) async {
  //       await _auth.signInWithCredential(credential);
  //     },
  //     verificationFailed: (FirebaseAuthException e) {
  //       print("Error: ${e.message}");
  //     },
  //     codeSent: (String verId, int? resendToken) {
  //       onCodeSent(verId); // Ye ID humein OTP verify karne ke liye chahiye
  //     },
  //     codeAutoRetrievalTimeout: (String verId) {},
  //   );
  // }

  // OTP verify karke login karna
  Future<void> verifyOTP(String verId, String otpCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verId,
      smsCode: otpCode,
    );
    await _auth.signInWithCredential(credential);
  }
}