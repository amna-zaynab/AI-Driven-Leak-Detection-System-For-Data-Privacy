# Quick Reference - Backend Connection

## ✅ What's Been Done

1. **Created API Service** (`lib/services/api_service.dart`)
   - Centralized API client for all backend calls
   - Error handling and timeout management (10 seconds)
   - Methods for: register, login, privacy score, permissions, breaches, phishing

2. **Updated Login Page** (`lib/login_page.dart`)
   - Now connects to Django backend for authentication
   - Shows loading indicator during login
   - Better error messages

3. **Updated Signup Page** (`lib/signup_page.dart`)
   - Uses new API service instead of local HTTP calls
   - Registers users with backend
   - Cleaner code structure

4. **Added Login Endpoint** (`django_permission_demo/api/views.py`)
   - New `/api/login/` endpoint
   - Validates email and password
   - Returns user info on success

## 🚀 Quick Start

### 1. Start Django Backend
```bash
cd django_permission_demo
python manage.py runserver 0.0.0.0:8000
```

### 2. Run Flutter App
```bash
flutter run
```

### 3. Test Flow
1. Click "Sign Up" on login page
2. Create account with email, password, phone
3. Return to login
4. Login with created credentials
5. See dashboard if successful

## 📡 API Endpoints Ready to Use

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/api/register/` | Create new user | ✅ Ready |
| POST | `/api/login/` | Authenticate user | ✅ Ready |
| GET | `/api/get_privacy_score/` | Get privacy score | ✅ Ready |
| POST | `/api/submit_permissions/` | Save app permissions | ✅ Ready |
| GET | `/api/get_breaches/{email}/` | Email breach check | ✅ Ready |
| GET | `/api/get_phone_breaches/{phone}/` | Phone breach check | ✅ Ready |
| POST | `/api/check_phishing_url/` | Check URL safety | ✅ Ready |
| GET | `/api/get_phishing_history/` | Phishing history | ✅ Ready |

## 🔧 Configuration

**Backend URL**: `http://10.0.2.2:8000` (Android emulator)

**To change for physical device**:
Edit [lib/services/api_service.dart](lib/services/api_service.dart), line 4:
```dart
static const String baseUrl = 'http://YOUR_IP:8000';
```

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection timeout" | Check if Django is running on `0.0.0.0:8000` |
| "Invalid credentials" | User email doesn't exist or password is wrong |
| "Email already registered" | Try signup with different email |
| Can't find backend | Update baseUrl with correct IP address |

## 📝 Important Notes

- Passwords are stored as plain text in backend (NOT SECURE - production needs hashing)
- All API calls have 10-second timeout
- Email must be unique for registration
- Phone field is optional on registration

## 📚 Files Modified

- ✅ [lib/login_page.dart](lib/login_page.dart)
- ✅ [lib/signup_page.dart](lib/signup_page.dart)
- ✅ [lib/services/api_service.dart](lib/services/api_service.dart) (NEW)
- ✅ [django_permission_demo/api/views.py](django_permission_demo/api/views.py)
- ✅ [django_permission_demo/api/urls.py](django_permission_demo/api/urls.py)

## 🔐 Next Steps (Recommended)

1. Test login/signup flow
2. Implement password hashing (Django: `make_password()`)
3. Add JWT token authentication
4. Update other pages to use API service
5. Add network error recovery
6. Test on physical device with correct IP

## 💡 Using API Service in Other Pages

Example: Get privacy score in your dashboard
```dart
import 'services/api_service.dart';

// Inside your page
try {
  final response = await ApiService.getPrivacyScore(email: userEmail);
  final score = response['privacy_score'];
  // Update UI with score
} catch (e) {
  print('Error: $e');
}
```

All API methods follow the same pattern:
1. Async function call
2. Try-catch for error handling
3. Returns Map<String, dynamic> or throws Exception
