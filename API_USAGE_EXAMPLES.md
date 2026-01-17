# How to Use API Service in Your Pages

## Example 1: Dashboard Page - Get User Breaches

```dart
import 'package:flutter/material.dart';
import 'services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userEmail = '';
  List<dynamic> _breaches = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    
    if (email != null) {
      setState(() => _userEmail = email);
      _checkBreaches(email);
    }
  }

  Future<void> _checkBreaches(String email) async {
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.getBreaches(email: email);
      
      if (response.containsKey('breaches')) {
        setState(() {
          _breaches = response['breaches'] ?? [];
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching breaches: $e';
        _breaches = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text('Error: $_errorMessage'))
              : _breaches.isEmpty
                  ? const Center(child: Text('No breaches found'))
                  : ListView.builder(
                      itemCount: _breaches.length,
                      itemBuilder: (context, index) {
                        final breach = _breaches[index];
                        return ListTile(
                          title: Text(breach['breach_name'] ?? 'Unknown'),
                          subtitle: Text(breach['breach_domain'] ?? 'N/A'),
                        );
                      },
                    ),
    );
  }
}
```

## Example 2: Email Breach Check Page

```dart
Future<void> _checkEmail(String email) async {
  setState(() => _isLoading = true);
  
  try {
    final response = await ApiService.getBreaches(email: email);
    
    final breaches = response['breaches'] ?? [];
    final breachCount = response['count'] ?? 0;
    
    if (breachCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Found $breachCount breaches!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ No breaches found')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

## Example 3: Check Phishing URL

```dart
Future<void> _checkPhishingUrl(String url, String userEmail) async {
  try {
    final response = await ApiService.checkPhishingUrl(
      email: userEmail,
      url: url,
    );
    
    final riskLevel = response['risk_level'] ?? 'unknown';
    final isPhishing = response['is_phishing'] ?? false;
    final threats = response['threats'] ?? [];
    
    String message;
    Color color;
    
    if (isPhishing) {
      message = '🚨 PHISHING DETECTED';
      color = Colors.red;
    } else if (riskLevel == 'suspicious') {
      message = '⚠️ SUSPICIOUS';
      color = Colors.orange;
    } else {
      message = '✅ SAFE';
      color = Colors.green;
    }
    
    // Show result dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message, style: TextStyle(color: color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Risk Level: $riskLevel'),
            const SizedBox(height: 10),
            ...threats.map((threat) => Text('• $threat')).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

## Example 4: Get Privacy Score

```dart
Future<void> _loadPrivacyScore(String email) async {
  try {
    final response = await ApiService.getPrivacyScore(email: email);
    
    final score = response['privacy_score'] ?? 0;
    final percentage = response['percentage'] ?? 0;
    final riskLevel = response['risk_level'] ?? 'Unknown';
    
    setState(() {
      _privacyScore = score;
      _scorePercentage = percentage;
      _riskLevel = riskLevel;
    });
    
    // Update UI with score
  } catch (e) {
    print('Error loading privacy score: $e');
  }
}
```

## Example 5: Submit App Permissions

```dart
Future<void> _submitPermissions(List<String> permissions, String email) async {
  setState(() => _isLoading = true);
  
  try {
    final response = await ApiService.submitPermissions(
      email: email,
      permissions: permissions,
    );
    
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions submitted successfully')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

## API Service Methods - Reference

All methods are in `lib/services/api_service.dart`:

### Registration
```dart
await ApiService.register(
  name: 'John Doe',
  email: 'john@example.com',
  phone: '1234567890',
  password: 'password123',
);
```

### Login
```dart
final result = await ApiService.login(
  email: 'user@example.com',
  password: 'password123',
);
// Returns: {success, message, user_id, email, name, phone}
```

### Privacy Score
```dart
final result = await ApiService.getPrivacyScore(email: 'user@example.com');
// Returns: {privacy_score, percentage, risk_level, ...}
```

### Submit Permissions
```dart
await ApiService.submitPermissions(
  email: 'user@example.com',
  permissions: ['CAMERA', 'LOCATION', 'MICROPHONE'],
);
```

### Get Breaches
```dart
final result = await ApiService.getBreaches(email: 'user@example.com');
// Returns: {email, breaches: [{id, breach_name, breach_domain, ...}], count}
```

### Get Phone Breaches
```dart
final result = await ApiService.getPhoneBreaches(phone: '+1234567890');
// Returns: {phone, breaches: [...], count}
```

### Check Phishing URL
```dart
final result = await ApiService.checkPhishingUrl(
  email: 'user@example.com',
  url: 'https://suspicious-login.com',
);
// Returns: {success, url, risk_level, is_phishing, confidence_score, threats, details}
```

### Get Phishing History
```dart
final result = await ApiService.getPhishingHistory(email: 'user@example.com');
// Returns: {email, records: [{id, url, risk_level, ...}], count}
```

## Error Handling Pattern

All API methods throw exceptions. Use try-catch:

```dart
try {
  final response = await ApiService.someMethod(...);
  // Success - use response
} on SocketException {
  // Network error
  print('Network error - check internet connection');
} on TimeoutException {
  // Request timeout
  print('Request took too long - backend may be down');
} catch (e) {
  // Other errors
  print('Error: $e');
}
```

## Common Issues & Solutions

### Issue: "Connection timeout"
```dart
// Backend not running on correct IP
// Fix: Update baseUrl in api_service.dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:8000';
```

### Issue: "Null safety" warning
```dart
// Always check for null values from API response
final email = response['email'] ?? 'Unknown';
final breaches = response['breaches'] ?? [];
```

### Issue: "Invalid JSON" from backend
```dart
// Make sure you're passing correct parameter names
// Check Django endpoint documentation
// Log request before sending:
print('Request body: ${jsonEncode(requestData)}');
```

## Tips & Best Practices

1. **Always use try-catch** when calling API methods
2. **Show loading indicators** during API calls
3. **Handle null values** from response
4. **Check response status** before using data
5. **Store user email** after login for future API calls
6. **Validate input** before sending to backend
7. **Use mounted check** before setState in async functions

```dart
if (mounted) {
  setState(() => _isLoading = false);
}
```

8. **Cache data** when appropriate to reduce API calls
9. **Log errors** for debugging
10. **Test with both** emulator and physical device (different IP)
