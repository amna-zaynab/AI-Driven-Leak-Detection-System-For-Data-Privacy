import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your Django server URL
  // For Android emulator: http://10.0.2.2:8000
  // For physical device: http://YOUR_COMPUTER_IP:8000
  static const String baseUrl = 'http://192.168.1.8:8000';

  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/register/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone': phone,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Please check your backend server.',
              );
            },
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: ${e.toString()}');
    }
  }

  /// Login user with email and password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Please check your backend server.',
              );
            },
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  /// Get privacy score for user
  static Future<Map<String, dynamic>> getPrivacyScore({
    required String email,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/get_privacy_score/?email=$email'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch privacy score');
      }
    } catch (e) {
      throw Exception('Privacy score error: ${e.toString()}');
    }
  }

  /// Submit app permissions
  static Future<Map<String, dynamic>> submitPermissions({
    required String email,
    required List<String> permissions,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/submit_permissions/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'permissions': permissions}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit permissions');
      }
    } catch (e) {
      throw Exception('Submit permissions error: ${e.toString()}');
    }
  }

  /// Get breaches for email
  static Future<Map<String, dynamic>> getBreaches({
    required String email,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/get_breaches/$email/'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch breaches');
      }
    } catch (e) {
      throw Exception('Breach check error: ${e.toString()}');
    }
  }

  /// Get phone breaches
  static Future<Map<String, dynamic>> getPhoneBreaches({
    required String phone,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/get_phone_breaches/$phone/'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch phone breaches');
      }
    } catch (e) {
      throw Exception('Phone breach check error: ${e.toString()}');
    }
  }

  /// Check phishing URL
  static Future<Map<String, dynamic>> checkPhishingUrl({
    required String email,
    required String url,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/check_phishing_url/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'url': url}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check URL');
      }
    } catch (e) {
      throw Exception('URL check error: ${e.toString()}');
    }
  }

  /// Get phishing history
  static Future<Map<String, dynamic>> getPhishingHistory({
    required String email,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/get_phishing_history/?email=$email'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch phishing history');
      }
    } catch (e) {
      throw Exception('Phishing history error: ${e.toString()}');
    }
  }
}
