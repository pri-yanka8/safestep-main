import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:geolocator/geolocator.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(
          context, '/home'); 
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 50, // adjust logo size here
            ),
            const SizedBox(height: 40),
            Text(
              'Some stories could\'ve ended differently',
              style: GoogleFonts.saira(fontSize: 18.0, color: Colors.white
                  // fontWeight: FontWeight.bold,
                  ),
            )
          ],
        ),
      ),
    );
  }
}
