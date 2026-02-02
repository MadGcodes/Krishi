import 'dart:io';
import 'package:flutter/foundation.dart'; // Important for kIsWeb check
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// --- LOCALIZATION IMPORT ---
import '../l10n/app_localizations.dart';

import '../models/prediction_result.dart';
import '../services/recommendation_service.dart';

class DiseaseResultScreen extends StatefulWidget {
  final XFile imageFile;
  final PredictionResult result;

  const DiseaseResultScreen({
    Key? key,
    required this.imageFile,
    required this.result,
  }) : super(key: key);

  @override
  State<DiseaseResultScreen> createState() => _DiseaseResultScreenState();
}

class _DiseaseResultScreenState extends State<DiseaseResultScreen> {
  final RecommendationService _recommendationService = RecommendationService();

  // Modern Color Palette
  final Color _bgColor = const Color(0xFF121212); // Deep Dark Slate
  final Color _cardColor = const Color(
    0xFF1E1E1E,
  ); // Slightly lighter for cards
  final Color _accentColor = const Color(0xFFFF5252); // Modern Coral Red
  final Color _textColor = const Color(0xFFE0E0E0); // Off-white for readability

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, String>? _recommendations;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      final queryName = widget.result.diseaseName.replaceAll('_', ' ');
      final data = await _recommendationService.getRecommendations(queryName);

      if (mounted) {
        setState(() {
          _recommendations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Use localized error message if context is available,
          // otherwise fallback to English or simple string.
          // Since we are in 'mounted' check, context is safe.
          _errorMessage =
              AppLocalizations.of(context)?.drErrorFetch ??
              "Unable to fetch treatments.";
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPlatformAwareImage() {
    ImageProvider imgProvider;
    if (kIsWeb) {
      imgProvider = NetworkImage(widget.imageFile.path);
    } else {
      imgProvider = FileImage(File(widget.imageFile.path));
    }

    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        image: DecorationImage(image: imgProvider, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access Localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.drTitle, // Localized
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Hero Image Section ---
              _buildPlatformAwareImage(),

              const SizedBox(height: 24),

              // --- 2. Diagnosis Badge & Title ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.drDetectedIssue, // Localized
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.result.diseaseName.replaceAll('_', ' '),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Confidence Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accentColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "${(widget.result.confidence * 100).toStringAsFixed(1)}%",
                          style: GoogleFonts.poppins(
                            color: _accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.drConfidence, // Localized
                          style: GoogleFonts.inter(
                            color: _accentColor.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // --- 3. Divider with Label ---
              Row(
                children: [
                  Text(
                    l10n.drAiRecommendations, // Localized
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.1)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- 4. Dynamic Content ---
              if (_isLoading)
                _buildLoadingState(l10n)
              else if (_errorMessage != null)
                _buildErrorState()
              else if (_recommendations != null)
                _buildRecommendationList(l10n),

              const SizedBox(height: 40),

              // --- 5. Action Button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: _accentColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed:
                      () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.center_focus_strong_rounded),
                      const SizedBox(width: 12),
                      Text(
                        l10n.drBtnScanAgain, // Localized
                        style: GoogleFonts.poppins(
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
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          CircularProgressIndicator(color: _accentColor),
          const SizedBox(height: 16),
          Text(
            l10n.drLoading, // Localized
            style: GoogleFonts.inter(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationList(AppLocalizations l10n) {
    return Column(
      children: [
        _buildInfoCard(
          l10n.drCardDiagnosis, // Localized
          _recommendations!['Symptoms'],
          Icons.health_and_safety_outlined,
        ),
        _buildInfoCard(
          l10n.drCardCause, // Localized
          _recommendations!['Cause'],
          Icons.psychology_alt_outlined,
        ),
        _buildInfoCard(
          l10n.drCardOrganic, // Localized
          _recommendations!['Organic'],
          Icons.eco_outlined,
          isOrganic: true,
        ),
        _buildInfoCard(
          l10n.drCardChemical, // Localized
          _recommendations!['Chemical'],
          Icons.science_outlined,
        ),
        _buildInfoCard(
          l10n.drCardFertilizer, // Localized
          _recommendations!['Fertilizer'],
          Icons.water_drop_outlined,
        ),
        _buildInfoCard(
          l10n.drCardPrevention, // Localized
          _recommendations!['Prevention'],
          Icons.shield_moon_outlined,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    String? content,
    IconData icon, {
    bool isOrganic = false,
  }) {
    if (content == null ||
        content.isEmpty ||
        content.toLowerCase().contains("not specified")) {
      return const SizedBox.shrink();
    }

    // --- CLEANING LOGIC ---
    // 1. Replace literal '\n' with real newlines
    // 2. Remove '**' artifacts
    // 3. Remove stray quotes at start/end
    String cleanContent =
        content
            .replaceAll(r'\n', '\n')
            .replaceAll('**', '')
            .replaceAll('"', '')
            .trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        // Subtle border instead of stark contrast
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isOrganic
                      ? Colors.green.withOpacity(0.1)
                      : _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isOrganic ? Colors.greenAccent : _accentColor,
              size: 24,
            ),
          ),
          collapsedIconColor: Colors.white38,
          iconColor: Colors.white,
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: MarkdownBody(
                data: cleanContent,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(
                  p: GoogleFonts.inter(
                    color: _textColor,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  strong: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  // Styled bullet points
                  listBullet: TextStyle(
                    color: isOrganic ? Colors.greenAccent : _accentColor,
                    fontSize: 16,
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
