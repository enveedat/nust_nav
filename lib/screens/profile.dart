import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/database.dart';
import '../features/auth/screens/sign_in.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: DatabaseService.getUserById(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("User data not found.")),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        final fullName =
            "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}"
                .trim();
        final userType = userData['userType'] ?? 'N/A';
        final email = userData['email'] ?? 'N/A';
        final studentID = userData['studentID'] ?? 'N/A';
        final department = userData['department'] ?? 'N/A';
        final accessLevel = userData['userType'] ?? 'N/A';

        // ✅ FIX: placesVisited is a Map, not a List
        final Map<String, dynamic> visitedMap =
            userData['placesVisited'] as Map<String, dynamic>? ?? {};
        final placesVisited = visitedMap.length.toString();

        final totalDistance =
            userData['totalDistance'] != null
                ? "${userData['totalDistance']} km"
                : "0 km";
        final mostVisited = userData['mostVisited'] ?? 'Unknown';

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
                Text("User Profile", style: TextStyle(color: Colors.black)),
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFE6F0FF),
                  child: Icon(
                    Icons.account_circle,
                    color: Colors.blue,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  fullName.isEmpty ? 'User' : fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(userType, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                _buildSectionTitle("Personal Information"),
                _buildInfoCard(email, studentID, department, accessLevel),
                const SizedBox(height: 24),
                _buildSectionTitle("Navigation Statistics"),
                _buildStatsCards(placesVisited, totalDistance),
                const SizedBox(height: 24),
                _buildSectionTitle("Favorites"),
                _buildFavoritesCard(mostVisited),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard(
    String email,
    String studentID,
    String department,
    String accessLevel,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow("Email", email),
          _buildInfoRow("Student ID", studentID),
          _buildInfoRow("Department", department),
          _buildInfoRow(
            "Access Level",
            "",
            trailingWidget: Chip(
              label: Text(
                accessLevel,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailingWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          trailingWidget ??
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatsCards(String placesVisited, String totalDistance) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(Icons.place, "Places Visited", placesVisited),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            Icons.transfer_within_a_station_rounded,
            "Total Distance",
            totalDistance,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFavoritesCard(String mostVisited) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.book, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mostVisited,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                "Most visited location",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
