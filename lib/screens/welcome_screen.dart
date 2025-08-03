
import 'package:flutter/material.dart';
import 'package:loomopro/screens/auth/auth_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to LoomoPro',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            const Text(
              'Please select your role:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectRole(context, 'artisan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('I am an Artisan', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectRole(context, 'customer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('I am a Customer', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
