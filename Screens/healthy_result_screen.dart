import 'dart:io';
import 'package:flutter/foundation.dart'; // Important for kIsWeb check
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // Import XFile
// --- LOCALIZATION IMPORT ---
import '../l10n/app_localizations.dart';

/// A screen displayed when the model predicts the plant is healthy.
/// This version is compatible with both Web and Mobile.
class HealthyResultScreen extends StatelessWidget {
  // Accepts an XFile, which works on all platforms.
  final XFile imageFile;

  const HealthyResultScreen({Key? key, required this.imageFile})
    : super(key: key);

  /// A helper widget to display the image from an XFile on both platforms.
  Widget _buildPlatformAwareImage() {
    // For web, the XFile path is a URL that Image.network can handle.
    if (kIsWeb) {
      return Image.network(
        imageFile.path,
        height: 250,
        width: 250,
        fit: BoxFit.cover,
      );
    }
    // For mobile, we use the path to create a File and use Image.file.
    return Image.file(
      File(imageFile.path),
      height: 250,
      width: 250,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access Localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1a2a1a),
      appBar: AppBar(
        title: Text(
          l10n.healthyResultTitle, // Localized
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Display the scanned image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildPlatformAwareImage(),
              ),
              const SizedBox(height: 32),
              // Healthy status icon and text
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent),
                    const SizedBox(width: 12),
                    Text(
                      l10n.healthyStatus, // Localized
                      style: GoogleFonts.poppins(
                        color: Colors.greenAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.healthySubtitle, // Localized
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              // Scan another button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // Pop until we get back to the home screen of the app
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  l10n.healthyActionScan, // Localized
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
