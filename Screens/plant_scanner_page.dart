import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
// --- LOCALIZATION IMPORT ---
import '../l10n/app_localizations.dart';

// Services
import '../services/api_service.dart';
import '../services/leaf_detector_service.dart';
// Screens
import 'processing_screen.dart';

class PlantScannerPage extends StatefulWidget {
  const PlantScannerPage({Key? key}) : super(key: key);

  @override
  State<PlantScannerPage> createState() => _PlantScannerPageState();
}

class _PlantScannerPageState extends State<PlantScannerPage> {
  // Instance of services
  final ApiService _apiService = ApiService();
  final LeafDetectorService _leafDetectorService = LeafDetectorService();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  /// Requests permissions. Skips storage permission on web.
  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    if (!kIsWeb) {
      await Permission.storage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScanScreen(
      apiService: _apiService,
      leafDetectorService: _leafDetectorService,
    );
  }
}

class ScanScreen extends StatelessWidget {
  final ApiService apiService;
  final LeafDetectorService leafDetectorService;

  const ScanScreen({
    Key? key,
    required this.apiService,
    required this.leafDetectorService,
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    // If an image was successfully picked, navigate to the ProcessingScreen.
    if (image != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ProcessingScreen(
                imageFile: image,
                apiService: apiService,
                leafDetectorService: leafDetectorService,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020), // deep, modern background
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Subtle blurred background image for depth
            Positioned.fill(
              child: Opacity(
                opacity: 0.18,
                child: Image.network(
                  'https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?w=1600',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Container(color: const Color(0xFF0B1020)),
                ),
              ),
            ),

            // 2. Top bar with glass effect
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _TopBar(
                onClose: () => Navigator.pop(context),
                onHome: () => Navigator.popUntil(context, (r) => r.isFirst),
              ),
            ),

            // 3. Center scan card
            Center(
              child: SingleChildScrollView(
                child: FractionallySizedBox(
                  widthFactor: 0.86,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title card
                      _TitleCard(),
                      const SizedBox(height: 18),

                      // Scan frame + hint container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Scanning window
                            AspectRatio(aspectRatio: 1, child: _ScanWindow()),
                            const SizedBox(height: 12),
                            Text(
                              l10n.scanHintAlign, // Localized Hint
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Spacing between box and controls
                      const SizedBox(height: 40),

                      // Controls Row (Gallery and Shutter)
                      _ControlsRow(
                        onGallery:
                            () => _pickImage(context, ImageSource.gallery),
                        onShutter:
                            () => _pickImage(context, ImageSource.camera),
                      ),

                      const SizedBox(height: 40), // Bottom padding for scroll
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SUB WIDGETS ---

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onHome;
  const _TopBar({required this.onClose, required this.onHome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _GlassIconButton(
          icon: Icons.home_outlined,
          label: l10n.scanBtnHome, // Localized
          onTap: onHome,
        ),
        const Spacer(),
        _GlassIconButton(
          icon: Icons.info_outline,
          label: l10n.scanBtnGuide, // Localized
          onTap:
              () => showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      backgroundColor: const Color(0xFF0C1222),
                      title: Text(
                        l10n.scanGuideTitle, // Localized
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      content: Text(
                        l10n.scanGuideMessage, // Localized
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.scanGuideGotIt), // Localized
                        ),
                      ],
                    ),
              ),
        ),
        const SizedBox(width: 8),
        _GlassIconButton(
          icon: Icons.close,
          label: l10n.scanBtnClose, // Localized
          onTap: onClose,
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.scanTitle, // Localized
                style: GoogleFonts.ibmPlexSans(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.scanSubtitle, // Localized
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        // subtle badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade700.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.eco, color: Colors.greenAccent.shade100, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.scanBadgeBeta,
                style: GoogleFonts.inter(color: Colors.white70),
              ), // Localized
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanWindow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Modern rounded square with inner subtle grid and corner accents
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Stack(
        children: [
          // faint guide grid (decorative)
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // corner accents
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                children: [
                  const Row(
                    children: [
                      _CornerAccent(alignment: Alignment.topLeft),
                      Spacer(),
                      _CornerAccent(alignment: Alignment.topRight),
                    ],
                  ),
                  const Spacer(),
                  const Row(
                    children: [
                      _CornerAccent(alignment: Alignment.bottomLeft),
                      Spacer(),
                      _CornerAccent(alignment: Alignment.bottomRight),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final Alignment alignment;
  const _CornerAccent({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.greenAccent.shade100.withOpacity(0.9),
            Colors.green.shade700.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade900.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.02)
          ..strokeWidth = 1;

    // draw subtle grid
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Updated Controls Row
class _ControlsRow extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onShutter;

  const _ControlsRow({required this.onGallery, required this.onShutter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _RoundIcon(
          icon: Icons.photo_library,
          label: l10n.scanBtnGallery, // Localized
          onTap: onGallery,
        ),
        // Shutter button is larger, so it naturally takes center stage
        _ShutterButton(onTap: onShutter),
        // Invisible container for symmetry
        const SizedBox(width: 64, height: 86),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoundIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShutterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.green.shade400, Colors.green.shade800],
            center: const Alignment(-0.2, -0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade900.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 3),
        ),
        child: Center(
          child: Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
