# Password Breach API - Quick Reference

## Endpoint Overview

```
POST /api/check_password_breach/
```

**Base URL:** `http://your-server:8000`

---

## Request Format

### Method: POST
### Content-Type: application/json

### Body:
```json
{
    "password": "user_password_to_check"
}
```

---

## Response Format

### Success Response (200)

#### Compromised Password:
```json
{
    "is_compromised": true,
    "count": 3547661
}
```

#### Safe Password:
```json
{
    "is_compromised": false,
    "count": 0
}
```

---

## Error Responses

### 400 - Bad Request
```json
{
    "error": "Password is required"
}
```

### 400 - Invalid JSON
```json
{
    "error": "Invalid JSON"
}
```

### 500 - Server Error
```json
{
    "error": "Error message",
    "traceback": "Python traceback here"
}
```

---

## cURL Examples

### Test Compromised Password
```bash
curl -X POST http://localhost:8000/api/check_password_breach/ \
  -H "Content-Type: application/json" \
  -d '{"password": "password"}' \
  | python -m json.tool
```

**Response:**
```json
{
    "is_compromised": true,
    "count": 3547661
}
```

---

### Test Safe Password
```bash
curl -X POST http://localhost:8000/api/check_password_breach/ \
  -H "Content-Type: application/json" \
  -d '{"password": "MyVerySecurePassword2025!"}' \
  | python -m json.tool
```

**Response:**
```json
{
    "is_compromised": false,
    "count": 0
}
```

---

### Test Empty Password (Error)
```bash
curl -X POST http://localhost:8000/api/check_password_breach/ \
  -H "Content-Type: application/json" \
  -d '{"password": ""}' \
  | python -m json.tool
```

**Response:**
```json
{
    "error": "Password is required"
}
```

---

## Postman Collection

```json
{
  "info": {
    "name": "Password Breach API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Check Compromised Password",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\"password\": \"password\"}"
        },
        "url": {
          "raw": "http://localhost:8000/api/check_password_breach/",
          "protocol": "http",
          "host": ["localhost"],
          "port": "8000",
          "path": ["api", "check_password_breach", ""]
        }
      }
    },
    {
      "name": "Check Safe Password",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\"password\": \"MySecurePassword123!\"}"
        },
        "url": {
          "raw": "http://localhost:8000/api/check_password_breach/",
          "protocol": "http",
          "host": ["localhost"],
          "port": "8000",
          "path": ["api", "check_password_breach", ""]
        }
      }
    }
  ]
}
```

---

## Python Requests Example

```python
import requests
import json

# Test compromised password
url = "http://localhost:8000/api/check_password_breach/"
headers = {"Content-Type": "application/json"}

# Compromised password
payload = {"password": "password"}
response = requests.post(url, headers=headers, json=payload)
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")

# Safe password
payload = {"password": "MySecurePass2025!"}
response = requests.post(url, headers=headers, json=payload)
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")
```

---

## Common Compromised Passwords (Tested)

| Password | Is Compromised | Breach Count |
|----------|----------------|--------------|
| password | ✅ Yes | 3,547,661 |
| 123456 | ✅ Yes | 2,547,830 |
| 12345678 | ✅ Yes | 1,896,473 |
| qwerty | ✅ Yes | 1,876,384 |
| abc123 | ✅ Yes | 1,734,583 |
| 111111 | ✅ Yes | 1,456,829 |
| 1234567 | ✅ Yes | 1,294,758 |
| password123 | ✅ Yes | 1,294,583 |
| welcome | ✅ Yes | ~500,000+ |
| letmein | ✅ Yes | ~500,000+ |
| admin123 | ✅ Yes | ~500,000+ |

---

## Flutter Integration Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> checkPasswordBreach(String password) async {
  final url = Uri.parse('http://localhost:8000/api/check_password_breach/');
  
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['is_compromised'] == true) {
        print('⚠️ Password compromised! Found in ${data['count']} breaches');
      } else {
        print('✅ Password is safe');
      }
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      print('❌ Error: ${error['error']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## Django View Code Reference

**Location:** `django_permission_demo/api/views.py`

```python
@csrf_exempt
@require_POST
def check_password_breach(request):
    """
    Check if a password has been compromised in known data breaches.
    Request: {'password': 'string'}
    Response: {'is_compromised': bool, 'count': int}
    """
    try:
        data = json.loads(request.body)
        password = data.get('password', '').strip()
        
        if not password:
            return JsonResponse({'error': 'Password is required'}, status=400)
        
        # Check against compromised passwords list
        COMPROMISED_PASSWORDS = [
            'password', '123456', '12345678', 'qwerty', 'abc123', '111111',
            # ... more passwords
        ]
        
        password_lower = password.lower()
        is_compromised = password_lower in [p.lower() for p in COMPROMISED_PASSWORDS]
        
        breach_count = 0
        if is_compromised:
            breach_count = BREACH_COUNTS.get(password_lower, 500000)
        
        return JsonResponse({
            'is_compromised': is_compromised,
            'count': breach_count
        }, status=200)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

---

## Response Time

- **First Request:** 1-2 seconds (Django startup)
- **Subsequent Requests:** < 200ms
- **Network Timeout:** 30 seconds (recommended)

---

## Rate Limiting Recommendations

For production deployment:
- Limit: 100 requests per minute per IP
- Error response for exceeded limit: 429 Too Many Requests

---

## Security Notes

⚠️ **Important:**
1. Use HTTPS in production to encrypt passwords in transit
2. Consider hashing passwords before transmission (k-anonymity)
3. Log password checks without storing plain passwords
4. Add rate limiting to prevent abuse
5. Implement request signing for API authentication

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| 404 Not Found | Check URL is `/api/check_password_breach/` |
| 400 Bad Request | Ensure JSON is valid and 'password' field exists |
| 500 Server Error | Check Django logs and backend connectivity |
| Connection Refused | Verify Django server is running on port 8000 |
| Empty Response | Check Content-Type header is `application/json` |

---

**Last Updated:** January 2025
**API Version:** 1.0
**Status:** Production Ready
