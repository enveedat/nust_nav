import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/auth/screens/sign_in.dart';
import '../../core/services/database.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: const [
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Text(
                "NU",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            SizedBox(width: 10),
            Text("Dashboard", style: TextStyle(color: Colors.black)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showUserMenu(context),
              child: const Icon(
                Icons.account_circle_outlined,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(context),
          const SizedBox(height: 20),
          _buildNavigationButtons(context),
          const SizedBox(height: 20),
          _buildKeyLocations(context),
          const SizedBox(height: 20),
          _buildTodaysEvents(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Welcome to NUST",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Navigate the campus safely",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/map'),
            child: const Text("Open Map", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navButton(context, Icons.list, "All Locations", '/locations'),
        _navButton(context, Icons.event, "All Events", '/events'),
      ],
    );
  }

  Widget _navButton(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyLocations(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("User not signed in."));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: DatabaseService.getUserById(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Failed to load key locations."));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 4,
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No key locations found."));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final placesVisited = Map<String, dynamic>.from(
          data['placesVisited'] ?? {},
        );

        if (placesVisited.isEmpty) {
          return const Center(child: Text("No key locations found."));
        }

        final top3 =
            placesVisited.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        final topLocations = top3.take(3).map((e) => e.key).toList();

        final icons = [Icons.place, Icons.map, Icons.location_on];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Key Locations",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/locations'),
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(topLocations.length, (index) {
                return ActionChip(
                  avatar: Icon(
                    icons[index % icons.length],
                    size: 20,
                    color: Colors.blue,
                  ),
                  label: Text(topLocations[index]),
                  backgroundColor: Colors.grey.shade100,
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/locationDetail',
                      arguments: {'locationName': topLocations[index]},
                    );
                  },
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodaysEvents(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService.getEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Failed to load events."));
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          );
        }

        final todayEvents =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final eventDate = (data['eventDate'] as Timestamp).toDate();
              return DateFormat('yyyy-MM-dd').format(eventDate) == today;
            }).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Events",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/events'),
                    child: const Text(
                      "All Events",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (todayEvents.isEmpty)
                const Center(child: Text("No Events Today"))
              else
                ...todayEvents.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.event, color: Colors.blue),
                        title: Text(data['title'] ?? 'Event'),
                        subtitle: Text(data['description'] ?? ''),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tapped on ${data['title']}'),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showUserMenu(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                "User Menu",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (user != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Email: ${user.email}"),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
