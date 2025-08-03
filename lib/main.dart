import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/firebase_options.dart';
import 'package:loomopro/screens/auth/auth_wrapper.dart';
import 'package:loomopro/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final stopwatch = Stopwatch()..start();
  debugPrint('App startup: main() started at ${stopwatch.elapsedMilliseconds}ms');

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('App startup: WidgetsFlutterBinding initialized at ${stopwatch.elapsedMilliseconds}ms');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('App startup: Firebase initialized at ${stopwatch.elapsedMilliseconds}ms');

  runApp(const MyApp());
  debugPrint('App startup: runApp() called at ${stopwatch.elapsedMilliseconds}ms');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<Widget> _getStartScreen() async {
    final stopwatch = Stopwatch()..start();
    debugPrint('App startup: _getStartScreen() started at ${stopwatch.elapsedMilliseconds}ms');

    final prefs = await SharedPreferences.getInstance();
    debugPrint('App startup: SharedPreferences loaded at ${stopwatch.elapsedMilliseconds}ms');

    final role = prefs.getString('user_role');
    if (role != null) {
      debugPrint('App startup: User role found, navigating to AuthWrapper at ${stopwatch.elapsedMilliseconds}ms');
      return const AuthWrapper();
    }
    debugPrint('App startup: No user role, navigating to WelcomeScreen at ${stopwatch.elapsedMilliseconds}ms');
    return const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoomoPro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: FutureBuilder<Widget>(
        future: _getStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            debugPrint('App startup: FutureBuilder done at ${DateTime.now().millisecondsSinceEpoch}ms');
            return snapshot.data ?? const WelcomeScreen();
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
