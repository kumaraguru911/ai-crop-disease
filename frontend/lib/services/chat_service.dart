import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatService {
  static const String baseUrl = 'http://192.168.1.33:8000';

  static Future<String> sendMessage({
    required String message,
    String? prediction,
    double? confidence,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'prediction': prediction,
        'confidence': confidence,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] as String;
    }

    throw Exception('Chat API failed: ${response.statusCode}');
  }
}
