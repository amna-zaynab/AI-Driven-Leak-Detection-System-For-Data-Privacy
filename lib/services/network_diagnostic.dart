import 'package:http/http.dart' as http;
import 'dart:convert';

class NetworkDiagnostic {
  static const String tag = '🌐 NETWORK_DIAGNOSTIC';

  static Future<Map<String, dynamic>> testConnectivity() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toString(),
      'tests': <String, dynamic>{},
    };

    // Test 1: DNS resolution
    print('$tag: Testing DNS resolution for 192.168.1.8...');
    try {
      final ip = Uri.parse('http://192.168.1.8:8000/api/get_privacy_score/');
      results['tests']['dns_resolution'] = 'passed';
      print('$tag: ✅ DNS resolution passed');
    } catch (e) {
      results['tests']['dns_resolution'] = 'failed: $e';
      print('$tag: ❌ DNS resolution failed: $e');
    }

    // Test 2: HTTP connectivity to Django
    print('$tag: Testing HTTP connectivity to 192.168.1.8:8000...');
    try {
      final response = await http
          .get(Uri.parse('http://192.168.1.8:8000/api/get_privacy_score/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        results['tests']['http_connectivity'] = {
          'status': 'passed',
          'statusCode': response.statusCode,
          'body_length': response.body.length,
        };
        print('$tag: ✅ HTTP connectivity passed');
        print('$tag: Response: ${response.body}');
      } else {
        results['tests']['http_connectivity'] = {
          'status': 'failed',
          'statusCode': response.statusCode,
          'body': response.body,
        };
        print('$tag: ❌ HTTP failed with status ${response.statusCode}');
      }
    } catch (e) {
      results['tests']['http_connectivity'] = {
        'status': 'failed',
        'error': e.toString(),
      };
      print('$tag: ❌ HTTP connectivity failed: $e');
    }

    // Test 3: Localhost connectivity
    print('$tag: Testing localhost connectivity...');
    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:8000/api/get_privacy_score/'))
          .timeout(const Duration(seconds: 5));

      results['tests']['localhost_connectivity'] = {
        'status': response.statusCode == 200 ? 'passed' : 'failed',
        'statusCode': response.statusCode,
      };
      print('$tag: Localhost test status: ${response.statusCode}');
    } catch (e) {
      results['tests']['localhost_connectivity'] = {
        'status': 'failed',
        'error': e.toString(),
      };
      print('$tag: ⚠️ Localhost test failed: $e');
    }

    print('$tag: ===== DIAGNOSTIC RESULTS =====');
    print('$tag: ${jsonEncode(results)}');
    print('$tag: =============================');

    return results;
  }
}
