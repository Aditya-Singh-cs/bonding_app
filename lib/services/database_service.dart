import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // 1. Setup: Sirf fields ke naam update kiye hain
  Future<void> setupNewUser() async {
    if (uid == null) return;
    DocumentReference userRef = _db.collection('users').doc(uid);

    try {
      await _db.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          transaction.set(userRef, {
            'uid': uid,
            'phoneNumber': FirebaseAuth.instance.currentUser?.phoneNumber,
            'name': null, 
            'trialSeconds': 300,   // Naya logic: 5 min free
            'walletBalance': 0,    // Naya logic: Asli paise
            'isTrialUsed': false, 
            'role': 'user',       
            'createdAt': FieldValue.serverTimestamp(),
            'isOnline': true,
          });
        }
      });
    } catch (e) {
      print("Error setting up user: $e");
    }
  }

  // 2. Balance ghatana: Smart logic (Pehle trial, phir wallet)
  // Maine parameter ka naam 'amountUsed' hi rakha hai jo tune diya tha
  // Future<void> decreaseBalance(int amountUsed, {int pricePerMin = 0}) async {
  //   if (uid == null) return;
  //   DocumentReference userRef = _db.collection('users').doc(uid);
  //   try {
  //     await _db.runTransaction((transaction) async {
  //       DocumentSnapshot snapshot = await transaction.get(userRef);
  //       if (snapshot.exists) {
  //         var data = snapshot.data() as Map<String, dynamic>;
  //         int trial = data['trialSeconds'] ?? 0;
  //         int wallet = data['walletBalance'] ?? 0;

  //         if (trial > 0) {
  //           // Agar trial bacha hai, toh seconds ghatao
  //           int newTrial = (trial - amountUsed).clamp(0, 999999).toInt();
  //           transaction.update(userRef, {
  //             'trialSeconds': newTrial,
  //             'isTrialUsed': newTrial == 0,
  //           });
  //         } else if (pricePerMin > 0) {
  //           // Agar trial khatam, toh wallet se ₹ kato (Seconds to ₹ conversion)
  //           int rupeesToDeduct = ((amountUsed / 60) * pricePerMin).ceil();
  //           int newWallet = (wallet - rupeesToDeduct).clamp(0, 999999).toInt();
  //           transaction.update(userRef, {'walletBalance': newWallet});
  //         }
  //       }
  //     });
  //   } catch (e) { print("Error updating balance: $e"); }
  // }
  Future<void> decreaseBalance(int amountUsed, {required int pricePerMin}) async {
  if (uid == null) return;
  DocumentReference userRef = _db.collection('users').doc(uid);
  try {
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        int trial = data['trialSeconds'] ?? 0;
        int wallet = data['walletBalance'] ?? 0;
        bool trialUsed = data['isTrialUsed'] ?? false; // Flag fetch kiya

        // FIX: Agar trial bacha hai AUR pehle kabhi use nahi hua (Flag is false)
        if (trial > 0 && !trialUsed) {
          int newTrial = (trial - amountUsed).clamp(0, 999999).toInt();
          transaction.update(userRef, {
            'trialSeconds': newTrial,
            'isTrialUsed': newTrial <= 0, // Sirf tabhi true hoga jab 0 pahunchega
          });
        } else {
          // Agar trial used ho chuka hai, toh sidha wallet se kato
          int rupeesToDeduct = ((amountUsed / 60) * pricePerMin).ceil();
          int newWallet = (wallet - rupeesToDeduct).clamp(0, 999999).toInt();
          transaction.update(userRef, {
            'walletBalance': newWallet,
            'isTrialUsed': true, // Ye pakka karega ki flag TRUE hi rahe
          });
        }
      }
    });
  } catch (e) { print("Error: $e"); }
}

  // 3. getUserBalance: Pehle trial dikhayega, khatam hone par wallet
  Future<int> getUserBalance() async {
    if (uid == null) return 0;
    try {
      var doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        // Agar trial bacha hai toh seconds return karo, warna wallet ke Rupees
        return (data['trialSeconds'] ?? 0) > 0 
            ? data['trialSeconds'] 
            : data['walletBalance'] ?? 0;
      }
    } catch (e) { print("Error fetching balance: $e"); }
    return 0;
  }

  // --- TERE BAAKI FUNCTIONS (NO CHANGES AT ALL) ---

  Future<void> updateBuddySettings({required bool canText, required bool canCall, required bool canVideo}) async {
    if (uid == null) return;
    try {
      await _db.collection('buddies').doc(uid).update({'canText': canText, 'canCall': canCall, 'canVideo': canVideo});
    } catch (e) { print(e); }
  }

  Future<void> updateUserName(String name) async {
    if (uid == null) return;
    try { await _db.collection('users').doc(uid).update({'name': name}); } catch (e) { print(e); }
  }

  Future<bool> isNameSet() async {
    if (uid == null) return false;
    try {
      var doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        return data['name'] != null && data['name'].toString().isNotEmpty;
      }
    } catch (e) { print(e); }
    return false;
  }

  Future<void> saveCallRecord({required String buddyName, required int durationInSeconds}) async {
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).collection('call_history').add({
        'buddyName': buddyName, 'duration': durationInSeconds, 'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) { print(e); }
  }

  Future<void> deleteUserAccount() async {
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).delete();
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) { print(e); }
  }

  Future<void> addBalance(int amountToAdd) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'walletBalance': FieldValue.increment(amountToAdd),
    });
  }

  Future<void> saveBuddyRating({required String buddyName, required double rating}) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('ratings').add({
      'buddyName': buddyName, 'rating': rating, 'timestamp': FieldValue.serverTimestamp(),
    });
  }
}