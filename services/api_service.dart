import 'dart:convert';
import 'package:flutter/foundation.dart'; // Corrected import path
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/prediction_result.dart';

/// Service to handle communication with the backend prediction API.
/// This version is compatible with both Web and Mobile.
class ApiService {
  // IMPORTANT: Replace this with your actual Render API URL if it's different.
  final String _apiUrl = 'https://winkoo-plant-disease-api.hf.space/predict';

  /// Sends the image to the backend and returns a prediction.
  Future<PredictionResult> predict(XFile imageFile) async {
    try {
      final uri = Uri.parse(_apiUrl);
      final request = http.MultipartRequest('POST', uri);

      // Read the image file as bytes, which works on all platforms.
      final bytes = await imageFile.readAsBytes();

      // Create a MultipartFile from the bytes.
      final multipartFile = http.MultipartFile.fromBytes(
        'image', // This key must match what the Flask API expects.
        bytes,
        filename: imageFile.name, // The original filename.
      );

      // Add the file and any other fields to the request.
      request.files.add(multipartFile);
      request.fields['conf_threshold'] = '0.5'; // Example field

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedJson = jsonDecode(responseBody);
        return PredictionResult.fromJson(decodedJson);
      } else {
        // Provide more detailed error logging for debugging.
        final errorBody = await response.stream.bytesToString();
        print('Server Error: ${response.statusCode}');
        print('Error Body: $errorBody');
        throw Exception(
          'Failed to get prediction. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Catch network or other exceptions.
      print('Error calling API: $e');
      throw Exception(
        'Failed to connect to the server. Please check your connection.',
      );
    }
  }
}
