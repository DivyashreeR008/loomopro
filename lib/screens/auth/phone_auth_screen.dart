import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/screens/auth/auth_wrapper.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _verificationId = '';
  bool _otpSent = false;

  Future<void> _sendOtp() async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${_phoneNumberController.text}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(user.uid);
        final DataSnapshot snapshot = await userRef.get();

        final prefs = await SharedPreferences.getInstance();

        if (!snapshot.exists) {
          // New user - assign role as seller and create initial data
          await userRef.set({
            'uid': user.uid,
            'role': 'artisan',
            'unique_seller_id': user.uid, // Using UID as unique seller ID for now
            'phone_number': user.phoneNumber,
          });
          await prefs.setString('user_role', 'artisan');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthWrapper()), // AuthWrapper will handle routing to seller registration
            );
          }
        } else {
          // Existing user - retrieve role
          final String? role = snapshot.child('role').value as String?;
          if (role != null) {
            await prefs.setString('user_role', role);
          }
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify OTP: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixText: '+91',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendOtp,
              child: const Text('Send OTP'),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _verifyOtp,
                child: const Text('Verify OTP'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}