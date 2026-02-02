import 'dart:convert';
import 'package:http/http.dart' as http;

class RecommendationService {
  // Use the base URL that we know works
  static const String _baseUrl =
      'https://ravina0912-fertilizer-recomm.hf.space';

  Future<Map<String, String>> getRecommendations(String fullDiseaseName) async {
    try {
      // 1. Prepare the URL (using /predict as it responded correctly before)
      final Uri url = Uri.parse('$_baseUrl/predict');

      // 2. Split the string into 'Crop' and 'Disease'
      // Example Input: "corn common rust" -> Crop: "corn", Disease: "common rust"
      String crop = "";
      String disease = "";

      List<String> parts = fullDiseaseName.trim().split(' ');

      if (parts.isNotEmpty) {
        crop = parts[0]; // First word is usually the crop
        if (parts.length > 1) {
          // Join the rest of the words to form the disease name
          disease = parts.sublist(1).join(' ');
        } else {
          disease = "general issue"; // Fallback if no second word
        }
      }

      print("📤 Sending -> Crop: '$crop', Disease: '$disease'");

      // 3. Send the specific JSON format the server requested in the 422 error
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "crop": crop, // The server explicitly asked for this
          "disease": disease, // And this
        }),
      );

      if (response.statusCode == 200) {
        // Success! Decode the response.
        // If the server returns a string directly, use it.
        // If it returns {"data": ...}, parse it.
        // Based on the error, this looks like a custom FastAPI, so it might return just the string or JSON.
        String rawText = utf8.decode(response.bodyBytes);

        // Safety check: if it's a JSON string wrapper, unwrap it
        try {
          final jsonResponse = jsonDecode(rawText);
          if (jsonResponse is Map && jsonResponse.containsKey('treatment')) {
            rawText = jsonResponse['treatment'];
          } else if (jsonResponse is String) {
            // Sometimes the response is a double-encoded string
            rawText = jsonResponse;
          }
        } catch (_) {
          // If it's not JSON, it's likely the plain Markdown text we want
        }

        return _parseAIResponse(rawText);
      } else {
        print("❌ Server Error: ${response.statusCode}");
        print("❌ Body: ${response.body}");
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      print("Error fetching recommendations: $e");
      throw Exception('Error fetching recommendations');
    }
  }

  /// Parses the Llama-3 output format
  Map<String, String> _parseAIResponse(String text) {
    Map<String, String> result = {};

    result['Symptoms'] = _extractSection(text, 'Symptoms:', 'Cause:');
    result['Cause'] = _extractSection(text, 'Cause:', 'Chemical Treatment:');
    result['Chemical'] = _extractSection(
      text,
      'Chemical Treatment:',
      'Organic Treatment:',
    );
    result['Organic'] = _extractSection(
      text,
      'Organic Treatment:',
      'Fertilizer Recommendation:',
    );
    result['Fertilizer'] = _extractSection(
      text,
      'Fertilizer Recommendation:',
      'Prevention:',
    );
    result['Prevention'] = _extractSection(text, 'Prevention:', null);

    return result;
  }

  String _extractSection(String text, String startMarker, String? endMarker) {
    // Case-insensitive search for robustness
    final lowerText = text.toLowerCase();
    final lowerStart = startMarker.toLowerCase();

    final startIndex = lowerText.indexOf(lowerStart);
    if (startIndex == -1) return "Not specified";

    final contentStart = startIndex + startMarker.length;

    int endIndex;
    if (endMarker != null) {
      final lowerEnd = endMarker.toLowerCase();
      endIndex = lowerText.indexOf(lowerEnd, contentStart);
      if (endIndex == -1) endIndex = text.length;
    } else {
      endIndex = text.length;
    }

    return text.substring(contentStart, endIndex).trim();
  }
}
