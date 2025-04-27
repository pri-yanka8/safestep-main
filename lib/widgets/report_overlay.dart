import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as latlng_lib; // for distance

class ReportOverlay extends StatefulWidget {
  final LatLng latlng;
  const ReportOverlay({super.key, required this.latlng});

  @override
  State<ReportOverlay> createState() => _ReportOverlayState();
}

class _ReportOverlayState extends State<ReportOverlay> {
  String? selectedCategory;
  final notesController = TextEditingController();
  final List<String> categories = [
    'Harassment',
    'Suspicious activity',
    'Stray Dogs',
    'Poor Lighting',
    'Robbery',
    'Unsafe area',
    'Other',
  ];

  bool _submitting = false;
  List<String> previousCategories = []; // 🔥 new

  @override
  void initState() {
    super.initState();
    _fetchPreviousNearbyReports(); // 🔥 check nearby within 200m
  }

  Future<void> _fetchPreviousNearbyReports() async {
    final col = FirebaseFirestore.instance.collection('reports');
    final lat = widget.latlng.latitude;
    final lng = widget.latlng.longitude;

    try {
      final qs = await col.get();

      List<String> foundCategories = [];

      for (var doc in qs.docs) {
        final data = doc.data();
        final reportLat = data['latitude'] as double;
        final reportLng = data['longitude'] as double;
        final category = data['category'] as String?;

        final tappedPoint = latlng_lib.LatLng(lat, lng);
        final reportPoint = latlng_lib.LatLng(reportLat, reportLng);

        final distance = const latlng_lib.Distance().as(
          LengthUnit.Meter,
          tappedPoint,
          reportPoint,
        );

        if (distance <= 200 && category != null) {
          foundCategories.add(category);
        }
      }

      setState(() {
        previousCategories =
            foundCategories.toSet().toList(); // remove duplicates
      });
    } catch (e) {
      print('Error fetching nearby previous reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Report this place?'),
        const SizedBox(height: 12),

        // Category chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSel = cat == selectedCategory;
            return ChoiceChip(
              label: Text(cat),
              selected: isSel,
              onSelected: (_) =>
                  setState(() => selectedCategory = isSel ? null : cat),
              selectedColor: Colors.cyanAccent.shade100,
              backgroundColor: Colors.grey[800],
              labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Notes field
        TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),

        const SizedBox(height: 12),

        // 🔥 Previously reported for:
        if (previousCategories.isNotEmpty)
          Text(
            "Previously reported for: ${previousCategories.join(', ')}",
            style: const TextStyle(
                color: const Color.fromARGB(255, 117, 237, 255),
                fontStyle: FontStyle.italic,
                fontSize: 16),
          ),

        const SizedBox(height: 16),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (selectedCategory == null || _submitting)
                ? null
                : () async {
                    setState(() => _submitting = true);

                    final col =
                        FirebaseFirestore.instance.collection('reports');
                    final lat = widget.latlng.latitude;
                    final lng = widget.latlng.longitude;

                    String readableLocation = "Unknown location";

                    try {
                      List<Placemark> placemarks =
                          await placemarkFromCoordinates(lat, lng);

                      if (placemarks.isNotEmpty) {
                        final place = placemarks.first;
                        readableLocation =
                            "${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
                      }
                    } catch (e) {
                      print("Reverse geocoding failed: $e");
                    }

                    // Normal Submit logic
                    final qs = await col
                        .where('latitude', isEqualTo: lat)
                        .where('longitude', isEqualTo: lng)
                        .get();

                    if (qs.docs.isNotEmpty) {
                      final docRef = qs.docs.first.reference;
                      await docRef.update({
                        'reportCount': FieldValue.increment(1),
                        'category': selectedCategory,
                        'notes': FieldValue.arrayUnion([notesController.text]),
                        'timestamp': FieldValue.serverTimestamp(),
                        'location': readableLocation,
                      });
                    } else {
                      await col.add({
                        'latitude': lat,
                        'longitude': lng,
                        'category': selectedCategory,
                        'notes': [notesController.text],
                        'timestamp': FieldValue.serverTimestamp(),
                        'location': readableLocation,
                        'reportCount': 1,
                      });
                    }

                    if (mounted) Navigator.pop(context);
                  },
            child: _submitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit Report'),
          ),
        ),
      ],
    );
  }
}
