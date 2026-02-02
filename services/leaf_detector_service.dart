import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class LeafDetectorService {
  /// Returns true if the image is likely a leaf, plant, or crop.
  /// Uses a hybrid approach: ML Kit (Shape) + Pixel Analysis (Color).
  Future<bool> isLeaf(XFile imageFile) async {
    // 1. If on Web, we can only use pixel check (ML Kit doesn't support web)
    if (kIsWeb) {
      return await _checkGreenPercentage(imageFile, threshold: 15.0);
    }

    // 2. Run ML Kit Analysis
    final List<ImageLabel> labels = await _getMLKitLabels(imageFile);

    // 3. Define keywords
    final plantKeywords = [
      'plant',
      'leaf',
      'vegetable',
      'fruit',
      'flower',
      'crop',
      'tree',
      'herb',
      'grass',
      'agriculture',
    ];
    final banKeywords = [
      'car',
      'vehicle',
      'phone',
      'electronic',
      'building',
      'furniture',
      'person',
      'animal',
    ];

    bool foundPlant = false;
    bool foundBannedObject = false;

    debugPrint("🔍 Analyzing Image Labels...");
    for (var label in labels) {
      String text = label.label.toLowerCase();
      double confidence = label.confidence;
      debugPrint("   - $text (${(confidence * 100).toStringAsFixed(1)}%)");

      if (plantKeywords.any((k) => text.contains(k))) foundPlant = true;
      if (banKeywords.any((k) => text.contains(k)) && confidence > 0.7)
        foundBannedObject = true;
    }

    // --- DECISION LOGIC ---

    // CASE A: ML Kit is sure it is a plant.
    if (foundPlant) {
      debugPrint("✅ ML Kit confirmed it is a plant.");
      return true;
    }

    // CASE B: ML Kit is sure it is a NON-plant (like a car).
    if (foundBannedObject) {
      debugPrint("❌ ML Kit detected a banned object (Non-plant).");
      return false;
    }

    // CASE C: ML Kit is unsure (e.g., Zoomed in leaf, just sees "Texture" or "Green").
    // We fall back to your "Green Pixel" logic.
    debugPrint("⚠️ ML Kit unsure. Falling back to Green Pixel Analysis...");

    // We use a slightly stricter threshold (e.g., 25%) for the fallback
    // to ensure we don't accidentally accept a green wall.
    bool isGreen = await _checkGreenPercentage(imageFile, threshold: 25.0);

    if (isGreen) {
      debugPrint("✅ Color Analysis passed (Zoomed-in Leaf detected).");
      return true;
    } else {
      debugPrint("❌ Color Analysis failed (Not green enough).");
      return false;
    }
  }

  // --- HELPER 1: ML Kit Wrapper ---
  Future<List<ImageLabel>> _getMLKitLabels(XFile file) async {
    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    final imageLabeler = ImageLabeler(options: options);
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      return await imageLabeler.processImage(inputImage);
    } catch (e) {
      debugPrint("Error in ML Kit: $e");
      return [];
    } finally {
      imageLabeler.close();
    }
  }

  // --- HELPER 2: Green Pixel Logic (Your original code) ---
  Future<bool> _checkGreenPercentage(
    XFile file, {
    required double threshold,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final double greenPercentage = await compute(
        _calculateGreenPercentage,
        bytes,
      );
      debugPrint("   🎨 Green Content: ${greenPercentage.toStringAsFixed(1)}%");
      return greenPercentage > threshold;
    } catch (e) {
      return false;
    }
  }

  static double _calculateGreenPercentage(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return 0.0;
    int greenPixelCount = 0;
    final totalPixels = image.width * image.height;
    for (final pixel in image) {
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      // Green dominance check
      if (g > r && g > b && g > 50 && (g + r + b) < 700) {
        greenPixelCount++;
      }
    }
    return (greenPixelCount / totalPixels) * 100.0;
  }
}
