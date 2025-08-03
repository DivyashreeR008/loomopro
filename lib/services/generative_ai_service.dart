
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GenerativeAiService {
  // WARNING: Do not ship your app with this key hardcoded.
  // This is a placeholder for development.
  // For production, use a secure method like a backend server or environment variables.
  static const _apiKey = 'YOUR_API_KEY_HERE';

  Future<String> generateDescription(
      String imageUrl, String audioFilePath) async {
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      return "Description generation is disabled. Please provide a valid Google AI API key in `lib/services/generative_ai_service.dart`.";
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash', // Using a fast and capable model
      apiKey: _apiKey,
    );

    // 1. Download the image from Firebase Storage to a temporary file
    final imageUri = Uri.parse(imageUrl);
    final imageRef = FirebaseStorage.instance.refFromURL(imageUrl);
    final imageBytes = await imageRef.getData();

    // 2. Prepare the audio file for upload
    final audioFile = File(audioFilePath);

    // 3. Construct the prompt with text, image, and audio
    final prompt = [
      Content.multi([
        TextPart(
            "You are an expert in describing handloom products for e-commerce. "
            "Based on the attached product image and the artisan's audio note, write a clear, appealing, and marketable product description. "
            "The artisan may not be a professional speaker, so focus on extracting key details they mention about the material, technique, color, and story. "
            "Structure the description nicely. If the artisan's audio is unclear or doesn't provide enough information, rely more on the product image. "
            "The final description should be in English."),
        DataPart('image/jpeg', imageBytes!),
        // The API expects a file URI for the audio
        DataPart('audio/mp4', await audioFile.readAsBytes()),
      ])
    ];

    // 4. Call the AI model
    final response = await model.generateContent(prompt);

    return response.text ?? "Could not generate a description. Please try again.";
  }
}
