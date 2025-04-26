import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestep/pages/HistoryScreen.dart';
import 'package:safestep/utils/mapscreen.dart';

import '../utils/current_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> testFirebaseConnection() async {
    try {
      await FirebaseFirestore.instance.collection('test').add({
        'check': 'success',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore write succeeded!');
    } catch (e) {
      print('❌ Firestore write failed: $e');
    }
  }

  double? _latitude;
  double? _longitude;
  bool _isFetching = true;
  bool _isEditingContact = false;

  final TextEditingController _contactController = TextEditingController();
  String? _emergencyContact;

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    try {
      Position pos = await CurrentLocation.getPosition();
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _isFetching = false;
      });
    } catch (e) {
      setState(() => _isFetching = false);
      print('Location error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF1C1C1E); // sleek dark shade

    return Scaffold(
      backgroundColor: themeColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(165),
        child: AppBar(
          backgroundColor: themeColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Location',
                    style: GoogleFonts.workSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isFetching
                        ? '📍 Fetching location...'
                        : (_latitude != null && _longitude != null
                            ? '📍 Gundlapochampally, Maisamma...'
                            : '📍 Location unavailable'),
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _emergencyContact != null && !_isEditingContact
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _isEditingContact = true;
                              _contactController.text = _emergencyContact!;
                            });
                          },
                          child: Text(
                            '📞 Emergency contact: $_emergencyContact',
                            style: GoogleFonts.workSans(
                              fontSize: 18,
                              color: Colors.greenAccent.shade100,
                            ),
                          ),
                        )
                      : TextField(
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.workSans(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter emergency contact',
                            hintStyle: GoogleFonts.workSans(
                              color: Colors.grey[500],
                            ),
                            filled: true,
                            fillColor: Colors.grey[850],
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.white),
                              onPressed: () {
                                if (_contactController.text.trim().isNotEmpty) {
                                  setState(() {
                                    _emergencyContact =
                                        _contactController.text.trim();
                                    _isEditingContact = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: MapScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the new screen when FAB is clicked
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HistoryScreen(),
            ),
          );
        },
        child: const Icon(Icons.history),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
