import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
// --- LOCALIZATION IMPORT ---
import '../l10n/app_localizations.dart';

import '../models/prediction_result.dart';
import '../services/api_service.dart';
import '../services/leaf_detector_service.dart';
import 'disease_result_screen.dart';
import 'healthy_result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final XFile imageFile;
  final ApiService apiService;
  final LeafDetectorService leafDetectorService;

  const ProcessingScreen({
    Key? key,
    required this.imageFile,
    required this.apiService,
    required this.leafDetectorService,
  }) : super(key: key);

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  // We initialize with empty strings or keys, but they get overwritten immediately
  String _statusText = '';
  String? _subStatusText; // Added to handle the small text cleanly
  PredictionResult? _result;
  String? _error;
  bool _isStarted = false; // To ensure we only start once

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We start processing here so we can access 'context' for Localization safely
    if (!_isStarted) {
      _isStarted = true;
      _processImage();
    }
  }

  Future<void> _processImage() async {
    // Get Localizations helper
    final l10n = AppLocalizations.of(context)!;

    try {
      // --- INITIAL STATE ---
      if (mounted) {
        setState(() {
          _statusText = l10n.procStatusAnalyzing;
        });
      }

      // --- STAGE 1: LEAF DETECTION ---
      if (mounted) {
        setState(() {
          _statusText = l10n.procStep1;
          _subStatusText = l10n.procStep1Sub;
        });
      }

      bool isLeaf = await widget.leafDetectorService.isLeaf(widget.imageFile);
      if (!mounted) return;

      if (!isLeaf) {
        // --- NOT A LEAF: Show error and go back ---
        setState(() {
          _error = l10n.procErrorNotLeaf;
          _subStatusText = null;
        });
        await Future.delayed(const Duration(seconds: 4));
        if (mounted) Navigator.pop(context);
        return;
      }

      // --- STAGE 2: DISEASE DETECTION ---
      setState(() {
        _statusText = l10n.procStep2;
        _subStatusText = l10n.procStep2Sub;
      });

      final result = await widget.apiService.predict(widget.imageFile);
      if (!mounted) return;

      setState(() {
        _result = result;
        _statusText = l10n.procComplete;
        _subStatusText = null;
      });

      // Navigate to the correct result screen
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        if (_result!.isHealthy) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => HealthyResultScreen(imageFile: widget.imageFile),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DiseaseResultScreen(
                    imageFile: widget.imageFile,
                    result: _result!,
                  ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Keep the raw exception for debugging, or map it if you have specific error codes
          _error = e.toString().replaceFirst('Exception: ', '');
          _subStatusText = null;
        });
        await Future.delayed(const Duration(seconds: 4));
        if (mounted) Navigator.pop(context);
      }
    }
  }

  /// Platform-aware image provider for the background.
  ImageProvider _buildImage() {
    if (kIsWeb) {
      return NetworkImage(widget.imageFile.path);
    }
    return FileImage(File(widget.imageFile.path));
  }

  @override
  Widget build(BuildContext context) {
    // Access l10n for static UI elements like "Processing Failed" title
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: _buildImage(),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black87.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error == null && _statusText != l10n.procComplete) ...[
                    // --- LOADING STATE ---
                    const SpinKitFadingCircle(color: Colors.green, size: 60),
                    const SizedBox(height: 24),
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_subStatusText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _subStatusText!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ] else if (_error != null) ...[
                    // --- ERROR STATE ---
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.procFailed,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ] else ...[
                    // --- SUCCESS STATE ---
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.procComplete,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
