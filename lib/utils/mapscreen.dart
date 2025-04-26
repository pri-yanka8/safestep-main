import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safestep/widgets/circular_gradient_marker.dart';
import 'package:safestep/widgets/report_overlay.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  // LatLng? _currentPosition;
  final LatLng _initialCenter = LatLng(17.5584280, 78.4511225);
  LatLng? tappedLatLng; // Store tapped location

  @override
  void initState() {
    super.initState();
    // _getCurrentLocation();
    _listenToReports();
  }

  // Future<void> _getCurrentLocation() async {
  //   try {
  //     Position position = await Geolocator.getCurrentPosition();
  //     setState(() {
  //       _currentPosition = LatLng(position.latitude, position.longitude);
  //     });
  //   } catch (e) {
  //     print("Error getting location: $e");
  //   }
  // }

  // Listen to real-time reports from Firestore
  void _listenToReports() {
    FirebaseFirestore.instance
        .collection('reports')
        .snapshots()
        .listen((snapshot) {
      List<Marker> markers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lat = data['latitude'] as double;
        final lng = data['longitude'] as double;
        final count = data['reportCount'] as int? ?? 1;

        // Calculate intensity based on report count
        final intensity = min(count / 3, 1.0);

        final marker = Marker(
          point: LatLng(lat, lng),
          width: 120,
          height: 120,
          child: CustomPaint(
            size: const Size(120, 120), // Custom size for your custom painter
            painter: CircularGradientMarker(
              intensity: intensity,
              reportCount: count,
            ),
          ),
        );

        markers.add(marker);
      }

      setState(() {
        _markers = markers;
      });
    });
  }

  // Handle map tap for report creation or update
  Future<void> _handleMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      tappedLatLng = point; // Save the tapped position for the report overlay
    });

    _showReportOverlay(point);
  }

  void _showReportOverlay(LatLng tappedLatLng) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.8,
          maxChildSize: 0.8,
          builder: (context, scrollCtrl) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: ReportOverlay(latlng: tappedLatLng),
              ),
            );
          },
        );
      },
    );
  }

  // Submit report after tapping submit button
  Future<void> _submitReport() async {
    if (tappedLatLng == null) return;

    bool reportExists = false;
    double minDistance = double.infinity;
    DocumentReference? existingReport;

    // Get all reports
    final reports =
        await FirebaseFirestore.instance.collection('reports').get();

    // Check for reports within 200 meters
    for (var doc in reports.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final reportLat = data['latitude'] as double;
      final reportLng = data['longitude'] as double;
      final reportPoint = LatLng(reportLat, reportLng);

      final distance = _calculateDistance(tappedLatLng!, reportPoint);

      if (distance <= 200 && distance < minDistance) {
        reportExists = true;
        minDistance = distance;
        existingReport = doc.reference;
      }
    }

    if (reportExists && existingReport != null) {

      await existingReport.update({
        'reportCount': FieldValue.increment(1),
      });
    } else {

      await FirebaseFirestore.instance.collection('reports').add({
        'latitude': tappedLatLng!.latitude,
        'longitude': tappedLatLng!.longitude,
        'reportCount': 1,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Function to calculate distance between two LatLng points
  double _calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371; // Radius of the Earth in km
    final dLat = _degreesToRadians(point2.latitude - point1.latitude);
    final dLon = _degreesToRadians(point2.longitude - point1.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(point1.latitude)) *
            cos(_degreesToRadians(point2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = R * c; // Distance in km
    return distance * 1000; // Convert to meters
  }

  // Function to convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    // if (_currentPosition == null) {
    //   return const Center(child: CircularProgressIndicator());
    // }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: 15,
        minZoom: 12,
        maxZoom: 20,
        onTap: _handleMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}.png?key=b6EEyvC7CYy4rbqanCcI',
        ),
        MarkerLayer(
          markers: [
            // Current location marker
            Marker(
              point: _initialCenter,
              width: 20,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.6), // Location pin color
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue,
                    width: 3, // Border width
                  ),
                ),
              ),
            ),
            ..._markers,
          ],
        ),
      ],
    );
  }
}
