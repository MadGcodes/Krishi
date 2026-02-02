import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import Localization
import 'l10n/app_localizations.dart';
import 'screens/plant_scanner_page.dart';

/// This is the main entry page for your disease detection feature.
/// It will be displayed when the user taps on the "Disease" nav bar item.
class DiseaseHomePage extends StatelessWidget {
  const DiseaseHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize Localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020), // THEME: Deep Blue Background
      body: Stack(
        children: [
          // 1. Background Image (Themed with Opacity)
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.network(
                'https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?w=1600',
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) =>
                        Container(color: const Color(0xFF0B1020)),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // --- CUSTOM HEADER (Replaces standard AppBar) ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.eco, color: Colors.greenAccent),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.plantDiseaseScanner, // Translated
                        style: GoogleFonts.ibmPlexSans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // --- HERO SECTION (Glowing Icon) ---
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.shade900.withOpacity(0.3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade500.withOpacity(0.2),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        // Original Icon (Themed Color)
                        const Icon(
                          Icons.document_scanner_outlined,
                          size: 100,
                          color: Colors.greenAccent,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // --- GLASS CARD (Text + Button) ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Original Headline
                        Text(
                          l10n.identifyDiseases, // Translated
                          style: GoogleFonts.ibmPlexSans(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Original Description
                        Text(
                          l10n.scanDescription, // Translated
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- THEMED BUTTON (Replaces ElevatedButton) ---
                        GestureDetector(
                          onTap: () {
                            // Original Logic: Navigate to Scanner
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PlantScannerPage(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade500,
                                  Colors.green.shade800,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.shade900.withOpacity(0.5),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.startScanning, // Translated
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
