# Backend Connection Setup Guide

## Overview
Your Flutter app is now connected to the Django backend. The connection is managed through a centralized API service.

## Backend Configuration

### Step 1: Update the Base URL
The API service is configured to connect to `http://10.0.2.2:8000` which is the default URL for Android emulators to reach the host machine.

**For different scenarios:**

- **Android Emulator**: `http://10.0.2.2:8000` ✓ (Already configured)
- **Physical Android Device**: `http://YOUR_COMPUTER_IP:8000`
  - Find your computer IP: Run `ipconfig` in PowerShell
  - Update `baseUrl` in [lib/services/api_service.dart](lib/services/api_service.dart#L4)
- **iOS Simulator**: `http://localhost:8000`
- **Web**: `http://localhost:8000`

### Step 2: Start Django Backend

```bash
# Navigate to the Django project
cd django_permission_demo

# Install dependencies (if not already done)
pip install -r requirements.txt

# Run the development server
python manage.py runserver 0.0.0.0:8000
```

The `0.0.0.0:8000` ensures the server listens on all network interfaces, making it accessible from both emulators and physical devices.

## Backend Endpoints Available

The following endpoints are now integrated into your Flutter app:

### Authentication
- **POST** `/api/register/` - Register new user
- **POST** `/api/login/` - Login user

### Privacy & Permissions
- **GET** `/api/get_privacy_score/?email={email}` - Get user's privacy score
- **POST** `/api/submit_permissions/` - Submit app permissions

### Breach Detection
- **GET** `/api/get_breaches/{email}/` - Get email breaches
- **GET** `/api/get_phone_breaches/{phone}/` - Get phone breaches

### Phishing Detection
- **POST** `/api/check_phishing_url/` - Check if URL is phishing
- **GET** `/api/get_phishing_history/?email={email}` - Get phishing history

## Flutter Implementation

### API Service Class
Location: [lib/services/api_service.dart](lib/services/api_service.dart)

This class handles all HTTP requests to the backend with:
- Built-in error handling
- 10-second timeout for all requests
- JSON serialization/deserialization
- Consistent response format

### Updated Pages

**Login Page** ([lib/login_page.dart](lib/login_page.dart))
- Now authenticates against the backend
- Shows loading indicator during login
- Stores user email in SharedPreferences after successful login

**Signup Page** ([lib/signup_page.dart](lib/signup_page.dart))
- Registers users with the backend
- Validates email, phone, and password format
- Returns to login page after successful registration

## Testing the Connection

### 1. Check Backend is Running
```bash
# In a terminal, you should see:
# Starting development server at http://127.0.0.1:8000/
```

### 2. Test Backend Directly
```bash
# Test registration
curl -X POST http://localhost:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","phone":"1234567890","password":"password123"}'

# Test login
curl -X POST http://localhost:8000/api/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### 3. Test from Flutter App
1. Run the Flutter app
2. Go to Signup page
3. Register a new account
4. Go back to Login page
5. Login with the registered credentials

## Troubleshooting

### "Connection timeout" Error
- **Check**: Is Django server running? (`python manage.py runserver`)
- **Check**: Is the base URL correct for your device/emulator?
- **Fix**: Update `baseUrl` in [api_service.dart](lib/services/api_service.dart)

### "Invalid JSON" Error
- **Check**: Django request body parsing is correct
- **Check**: Content-Type header is set to 'application/json'
- **Solution**: Backend is handling this; check Django logs

### 404 Not Found
- **Check**: Are all API endpoints registered in `django_permission_demo/api/urls.py`?
- **Check**: Is the URL path exactly matching what's in urls.py?

### User Registration/Login Fails
- **Check**: The backend's `register` endpoint expects: `name`, `email`, `phone`, `password`
- **Check**: Email must be unique (first check existing database)
- **Solution**: Check Django console for specific error messages

## Backend Model Reference

The Django backend expects a `UserProfile` model with these fields:
- `name` (CharField)
- `email` (CharField, unique)
- `phone` (CharField)
- `password` (CharField) - should be hashed in production

## Security Notes

⚠️ **For Production:**
1. Password should be hashed before storing (use Django's `make_password()`)
2. Use HTTPS instead of HTTP
3. Set up CORS properly
4. Implement JWT or session authentication
5. Add rate limiting
6. Validate all inputs on the backend

## Next Steps

1. Update the `login` endpoint in your Django backend if it's not already implemented
2. Test all endpoints with the Flutter app
3. Implement proper password hashing
4. Add error handling for network failures
5. Implement token-based authentication for API security
