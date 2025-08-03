
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/screens/artisan/artisan_dashboard_screen.dart';
import 'package:loomopro/screens/artisan/create_artisan_profile_screen.dart';
import 'package:loomopro/screens/auth/phone_auth_screen.dart';
import 'package:loomopro/screens/customer/customer_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<Widget> _getStartScreen() async {
    final stopwatch = Stopwatch()..start();
    debugPrint('AuthWrapper: _getStartScreen() started at ${stopwatch.elapsedMilliseconds}ms');

    final prefs = await SharedPreferences.getInstance();
    debugPrint('AuthWrapper: SharedPreferences loaded at ${stopwatch.elapsedMilliseconds}ms');

    final role = prefs.getString('user_role');
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('AuthWrapper: User role: $role, User: ${user?.uid} at ${stopwatch.elapsedMilliseconds}ms');

    if (user == null) {
      debugPrint('AuthWrapper: No user, navigating to PhoneAuthScreen at ${stopwatch.elapsedMilliseconds}ms');
      return const PhoneAuthScreen();
    }

    if (role == 'artisan') {
      debugPrint('AuthWrapper: User is artisan, checking profile at ${stopwatch.elapsedMilliseconds}ms');
      // 1. Check local cache first for speed
      final hasProfile = prefs.getBool('has_artisan_profile') ?? false;
      if (hasProfile) {
        debugPrint('AuthWrapper: Artisan profile found in cache at ${stopwatch.elapsedMilliseconds}ms');
        return const ArtisanDashboardScreen();
      }

      // 2. If not in cache, check database
      debugPrint('AuthWrapper: Artisan profile not in cache, checking database at ${stopwatch.elapsedMilliseconds}ms');
      final artisanRef =
          FirebaseDatabase.instance.ref('artisans/${user.uid}');
      final snapshot = await artisanRef.get();
      if (snapshot.exists) {
        debugPrint('AuthWrapper: Artisan profile found in database at ${stopwatch.elapsedMilliseconds}ms');
        // Save to cache for next time
        await prefs.setBool('has_artisan_profile', true);
        return const ArtisanDashboardScreen();
      } else {
        debugPrint('AuthWrapper: Artisan profile not found, navigating to CreateArtisanProfileScreen at ${stopwatch.elapsedMilliseconds}ms');
        return const CreateArtisanProfileScreen();
      }
    } else {
      debugPrint('AuthWrapper: User is customer, navigating to CustomerHomeScreen at ${stopwatch.elapsedMilliseconds}ms');
      return const CustomerHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('AuthWrapper: StreamBuilder waiting for auth state at ${DateTime.now().millisecondsSinceEpoch}ms');
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          debugPrint('AuthWrapper: User logged in, building FutureBuilder at ${DateTime.now().millisecondsSinceEpoch}ms');
          // User is logged in, determine the correct screen
          return FutureBuilder<Widget>(
            future: _getStartScreen(),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.done) {
                debugPrint('AuthWrapper: FutureBuilder done at ${DateTime.now().millisecondsSinceEpoch}ms');
                return futureSnapshot.data ?? const PhoneAuthScreen();
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        }
        // User is not logged in
        debugPrint('AuthWrapper: User not logged in, navigating to PhoneAuthScreen at ${DateTime.now().millisecondsSinceEpoch}ms');
        return const PhoneAuthScreen();
      },
    );
  }
}
