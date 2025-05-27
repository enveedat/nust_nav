import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../screens/dashboard.dart';
import 'sign_in.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading animation while checking auth status
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSplashBody(theme);
          }

          // Authenticated user
          if (snapshot.hasData) {
            return const DashboardScreen();
          }

          // Not authenticated
          return const LoginScreen();
        },
      ),
    );
  }

  Widget _buildSplashBody(ThemeData theme) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00AEEF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.map, size: 72, color: Color(0xFF00AEEF)),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              'Nust Navigator',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
