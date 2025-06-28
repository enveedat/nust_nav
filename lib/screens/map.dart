import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/services/database.dart';
import 'package:geolocator/geolocator.dart';

class CampusMapScreen extends StatefulWidget {
  final String? destinationName;
  final LatLng? destination;

  const CampusMapScreen({super.key, this.destinationName, this.destination});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  late GoogleMapController _mapController;
  LocationData? _currentLocation;
  final Location _location = Location();

  bool _isSatelliteView = false;
  bool _hasArrived = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final TextEditingController _searchController = TextEditingController();

  LatLng? _selectedDestination;
  Marker? _destinationMarker;

  final List<Map<String, dynamic>> _locationList = [];
  List<Map<String, dynamic>> _filteredLocations = [];

  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _fetchUserLocation();
    _loadLocationsFromFirestore();

    // Set search bar text if destinationName is passed
    if (widget.destinationName != null) {
      _searchController.text = widget.destinationName!;
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (widget.destination != null) {
      _destinationMarker = Marker(
        markerId: const MarkerId("destination"),
        position: widget.destination!,
        infoWindow: InfoWindow(
          title: widget.destinationName ?? "Selected Location",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );

      if (!mounted) return;
      setState(() {
        _selectedDestination = widget.destination!;
        _markers.add(_destinationMarker!);
        _addRoutePolyline();
      });

      await Future.delayed(const Duration(milliseconds: 500));
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: widget.destination!, zoom: 17),
        ),
      );
    }
  }

  Future<void> _fetchUserLocation() async {
    final hasPermission = await _location.requestPermission();
    if (hasPermission != PermissionStatus.granted) return;

    final locationData = await _location.getLocation();
    if (!mounted) return;

    setState(() {
      _currentLocation = locationData;
    });

    _locationSubscription = _location.onLocationChanged.listen((newLoc) {
      if (!mounted) return;
      setState(() => _currentLocation = newLoc);
      _checkProximity();
    });
  }

  Future<void> _loadLocationsFromFirestore() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('locations').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = data['locationName'];
      final GeoPoint pos = data['position'];

      final marker = Marker(
        markerId: MarkerId(name),
        position: LatLng(pos.latitude, pos.longitude),
        infoWindow: InfoWindow(title: name),
      );

      _locationList.add({
        'name': name,
        'latlng': LatLng(pos.latitude, pos.longitude),
      });

      if (!mounted) return;
      setState(() {
        _markers.add(marker);
        _filteredLocations = _locationList;
      });
    }
  }

  void _addRoutePolyline() {
    if (_currentLocation == null || _selectedDestination == null) return;

    final userPos = LatLng(
      _currentLocation!.latitude!,
      _currentLocation!.longitude!,
    );

    _polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        points: [userPos, _selectedDestination!],
        color: Colors.blue,
        width: 5,
      ),
    );
  }

  void _checkProximity() {
    if (_hasArrived || _currentLocation == null || _selectedDestination == null)
      return;

    final distance = Geolocator.distanceBetween(
      _currentLocation!.latitude!,
      _currentLocation!.longitude!,
      _selectedDestination!.latitude,
      _selectedDestination!.longitude,
    );

    if (distance < 20) {
      _hasArrived = true;
      _updateUserStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You’ve arrived at your destination!")),
        );
      }
    }
  }

  Future<void> _updateUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedDestination == null) return;

    final double dist = Geolocator.distanceBetween(
      _currentLocation!.latitude!,
      _currentLocation!.longitude!,
      _selectedDestination!.latitude,
      _selectedDestination!.longitude,
    );

    final locationName = _searchController.text.isNotEmpty
        ? _searchController.text
        : (widget.destinationName ?? 'Unknown');

    await DatabaseService.updateUserVisitStats(
      uid: user.uid,
      locationName: locationName,
      distanceTraveled: dist,
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Search locations...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onSubmitted: (query) {
        final match = _locationList.firstWhere(
          (loc) => loc['name'].toLowerCase() == query.toLowerCase(),
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          _selectedDestination = match['latlng'];
          _setDestination(match['latlng'], match['name']);
        }
      },
    );
  }

  void _setDestination(LatLng dest, String name) {
    if (!mounted) return;
    setState(() {
      _selectedDestination = dest;
      _destinationMarker = Marker(
        markerId: const MarkerId("destination"),
        position: dest,
        infoWindow: InfoWindow(title: name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      _markers.removeWhere((m) => m.markerId == const MarkerId("destination"));
      _markers.add(_destinationMarker!);
      _polylines.clear();
      _addRoutePolyline();
    });

    _mapController.animateCamera(CameraUpdate.newLatLngZoom(dest, 17));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    mapType:
                        _isSatelliteView ? MapType.satellite : MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentLocation!.latitude!,
                        _currentLocation!.longitude!,
                      ),
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _markers,
                    polylines: _polylines,
                  ),
                  Positioned(
                    top: 50,
                    left: 16,
                    right: 16,
                    child: _buildSearchBar(),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () {
                        if (!mounted) return;
                        setState(() => _isSatelliteView = !_isSatelliteView);
                      },
                      backgroundColor: Colors.white,
                      child: Icon(
                        _isSatelliteView ? Icons.map : Icons.satellite,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
