import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/sign_in.dart';
import 'firebase_options.dart';
import 'screens/locations.dart';
import 'screens/events.dart';
import 'screens/map.dart';
import 'screens/profile.dart';
import 'routes/navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NustNavigatorApp());
}

class NustNavigatorApp extends StatelessWidget {
  const NustNavigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NUST Navigator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SessionWrapper(), // Entry point depending on auth state
      onGenerateRoute: (settings) {
        if (settings.name == '/profile') {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: user.uid),
            );
          } else {
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
        }
        return null; // fallback to static routes
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainNavigation(),
        '/locations': (context) => const LocationsScreen(),
        '/events': (context) => const EventsScreen(),
        '/map': (context) => const CampusMapScreen(),
      },
    );
  }
}

class SessionWrapper extends StatelessWidget {
  const SessionWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigation(); // Signed-in users go to dashboard
        } else {
          return const LoginScreen(); // Unauthenticated users go to login
        }
      },
    );
  }
}
