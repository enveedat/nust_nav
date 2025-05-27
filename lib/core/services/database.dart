import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final CollectionReference users = _db.collection('users');
  static final CollectionReference events = _db.collection('events');
  static final CollectionReference locations = _db.collection('locations');

  // Add user on first login
  static Future<void> addUser(Map<String, dynamic> userData) async {
    final String? uid = userData['uid'];
    if (uid == null || uid.isEmpty) {
      throw Exception("User data must contain a valid 'uid' field");
    }

    await users.doc(uid).set({
      ...userData,
      'uid': uid, // Ensures UID is both doc ID and field
    });

    await initializeUserVisitStats(uid);
  }

  // Get user by their UID (document ID)
  static Future<DocumentSnapshot> getUserById(String uid) {
    return users.doc(uid).get();
  }

  // New method: Get user document by any field and value (e.g., 'uid')
  static Future<DocumentSnapshot> getUserByField(
    String field,
    String value,
  ) async {
    final querySnapshot =
        await users.where(field, isEqualTo: value).limit(1).get();

    if (querySnapshot.docs.isEmpty) {
      // Return an empty DocumentSnapshot with exists == false
      return _EmptyDocumentSnapshot();
    } else {
      return querySnapshot.docs.first;
    }
  }

  // Initialize location visit stats for new users
  static Future<void> initializeUserVisitStats(String uid) async {
    final userRef = users.doc(uid);
    final locationDocs = await locations.get();

    final Map<String, int> visitStats = {
      for (var doc in locationDocs.docs) doc['name']: 0,
    };

    await userRef.update({
      'placesVisited': visitStats,
      'totalDistance': 0.0,
      'mostVisited': '',
    });
  }

  // Ensure the user's visit stats include any newly added locations
  static Future<void> syncUserLocations(String uid) async {
    final userRef = users.doc(uid);
    final userSnap = await userRef.get();

    if (!userSnap.exists) return;

    final data = userSnap.data() as Map<String, dynamic>;
    final Map<String, dynamic> placesVisited = Map<String, dynamic>.from(
      data['placesVisited'] ?? {},
    );

    final locationDocs = await locations.get();

    bool updated = false;
    for (var doc in locationDocs.docs) {
      final locationName = doc['name'];
      if (!placesVisited.containsKey(locationName)) {
        placesVisited[locationName] = 0;
        updated = true;
      }
    }

    if (updated) {
      await userRef.update({'placesVisited': placesVisited});
    }
  }

  // Update stats when a user visits a location
  static Future<void> updateUserVisitStats({
    required String uid,
    required String locationName,
    required double distanceTraveled,
  }) async {
    final userRef = users.doc(uid);
    final userSnap = await userRef.get();

    if (!userSnap.exists) return;

    final data = userSnap.data() as Map<String, dynamic>;
    final Map<String, dynamic> placesVisited = Map<String, dynamic>.from(
      data['placesVisited'] ?? {},
    );
    final double totalDistance = (data['totalDistance'] ?? 0).toDouble();

    // Increment visits
    placesVisited[locationName] = (placesVisited[locationName] ?? 0) + 1;

    // Determine most visited location
    final mostVisited =
        placesVisited.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    await userRef.update({
      'placesVisited': placesVisited,
      'totalDistance': totalDistance + distanceTraveled,
      'mostVisited': mostVisited,
    });
  }

  // Add a new event
  static Future<void> addEvent(Map<String, dynamic> eventData) async {
    await events.add({...eventData, 'createdAt': FieldValue.serverTimestamp()});
  }

  // Get real-time stream of events
  static Stream<QuerySnapshot> getEventsStream() {
    return events.orderBy('eventDate').snapshots();
  }

  // Get a specific event
  static Future<DocumentSnapshot> getEventById(String eventId) {
    return events.doc(eventId).get();
  }

  // Get real-time stream of all locations
  static Stream<QuerySnapshot> getLocationsStream() {
    return locations.snapshots();
  }

  // Get a specific location
  static Future<DocumentSnapshot> getLocationById(String locationId) {
    return locations.doc(locationId).get();
  }

  // Add a new location
  static Future<void> addLocation(Map<String, dynamic> locationData) async {
    await locations.add({
      ...locationData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// Helper class to simulate a non-existent DocumentSnapshot
class _EmptyDocumentSnapshot implements DocumentSnapshot {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get exists => false;

  @override
  Map<String, dynamic>? data() => null;

  @override
  DocumentReference get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  String get id => '';
}
