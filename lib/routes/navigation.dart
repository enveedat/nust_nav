import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/dashboard.dart';
import '../screens/locations.dart';
import '../screens/events.dart';
import '../screens/map.dart';
import '../screens/profile.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  String? userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMapActive = _selectedIndex == 3;

    // Build the screen list dynamically with userId
    final List<Widget> screens = [
      const DashboardScreen(),
      const LocationsScreen(),
      const EventsScreen(),
      const CampusMapScreen(),
      userId != null
          ? ProfileScreen(userId: userId!)
          : const Center(child: Text("User not signed in")),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.list, 'Locations', 1),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(Icons.event, 'Events', 2),
              _buildNavItem(Icons.person, 'Profile', 4),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () => _onItemTapped(3),
          backgroundColor: isMapActive ? Colors.white : Colors.blue,
          shape: const CircleBorder(),
          child: Icon(
            Icons.map,
            size: 28,
            color: isMapActive ? Colors.blue : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
