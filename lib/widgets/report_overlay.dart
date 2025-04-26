import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart'; // 🆕 import for reverse geocoding

/// A bottom-sheet form that will either create a new report document
/// or increment an existing one at the same lat/lng.
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report this place?',
        ),
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

                    // 🔥 Reverse geocoding to get readable location
                    try {
                      List<Placemark> placemarks =
                          await placemarkFromCoordinates(lat, lng);
                      print('📍 Placemarks: $placemarks'); // Debug print

                      if (placemarks.isNotEmpty) {
                        final place = placemarks.first;
                        readableLocation =
                            "${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
                      }
                    } catch (e) {
                      print("Reverse geocoding failed: $e");
                    }

                    // 1️⃣ Look for an existing doc at this exact spot
                    final qs = await col
                        .where('latitude', isEqualTo: lat)
                        .where('longitude', isEqualTo: lng)
                        .get();

                    if (qs.docs.isNotEmpty) {
                      // 2️⃣ If found, increment its count
                      final docRef = qs.docs.first.reference;
                      await docRef.update({
                        'reportCount': FieldValue.increment(1),
                        'category': selectedCategory,
                        'notes': FieldValue.arrayUnion([notesController.text]),
                        'timestamp': FieldValue.serverTimestamp(),
                        'location': readableLocation, // <-- 🆕 update location
                      });
                    } else {
                      // 3️⃣ If not found, create new with count = 1
                      await col.add({
                        'latitude': lat,
                        'longitude': lng,
                        'category': selectedCategory,
                        'notes': [notesController.text],
                        'timestamp': FieldValue.serverTimestamp(),
                        'location': readableLocation, // <-- 🆕 save location
                        'reportCount': 1,
                      });
                    }

                    // Close sheet after submitting
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
