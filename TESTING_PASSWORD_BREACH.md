# Password Breach Feature - Testing Guide

## Quick Start

### 1. Start Django Backend

```bash
cd django_permission_demo
python manage.py runserver 0.0.0.0:8000
```

### 2. Configure Backend IP in App

In the Privacy App:
1. Go to Dashboard
2. Click the IP settings icon (top-right)
3. Enter your machine IP: `http://192.168.x.x:8000`

### 3. Navigate to Email/Password Breach Checker

From Dashboard → Email Breach Detection

## Test Cases

### Test 1: Common Compromised Password

**Input:** `password`
**Expected Result:**
- Compromised badge shows "🚨 Password Compromised!"
- Shows "Found in 3,547,661 known breaches"
- Red warning card with action message
- Button: "Get Security Tips"

**API Call:**
```bash
curl -X POST http://localhost:8000/api/check_password_breach/ \
  -H "Content-Type: application/json" \
  -d '{"password": "password"}'
```

**Expected Response:**
```json
{
    "is_compromised": true,
    "count": 3547661
}
```

### Test 2: Unique Safe Password

**Input:** `MyUniqueSecurePass123!`
**Expected Result:**
- Green checkmark "Good news!"
- Message: "No breaches found for this password"
- Recommendation: "Continue using strong passwords and enabling 2FA"

**API Call:**
```bash
curl -X POST http://localhost:8000/api/check_password_breach/ \
  -H "Content-Type: application/json" \
  -d '{"password": "MyUniqueSecurePass123!"}'
```

**Expected Response:**
```json
{
    "is_compromised": false,
    "count": 0
}
```

### Test 3: Common Password List

These should all return `is_compromised: true`:
- `123456` (count: 2547830)
- `12345678` (count: 1896473)
- `qwerty` (count: 1876384)
- `abc123` (count: 1734583)
- `letmein` (count: varies)
- `welcome` (count: varies)
- `admin123` (count: varies)

### Test 4: Empty Password

**Input:** (empty field)
**Expected Result:**
- Form validation error: "Password required"
- Button disabled until valid input

### Test 5: Tab Switching

1. Click "Email" tab
   - Form field changes to email input
   - Placeholder: "example@example.com"
   - Icon: Email icon
   - Label: "Email Address"

2. Click "Password" tab
   - Form field changes to password input
   - Text is obscured with dots
   - Placeholder: "Enter your password"
   - Icon: Key icon
   - Label: "Password"

3. Switch back to Email
   - Previous email input value is retained

### Test 6: Backend Connectivity

If backend is not configured:
- Error message: "Backend server not configured. Please check your server IP settings."
- Button: Still works (shows error)

## Debug Commands

### Check Django Endpoint

```bash
# Test with curl
curl -X POST http://localhost:8000/api/check_password_breach/ \
  -H "Content-Type: application/json" \
  -d '{"password": "password"}' | python -m json.tool

# Check Django logs
tail -f django_permission_demo/logs/*.log  # if logging is configured
```

### Check Flutter Logs

```bash
flutter logs
# Look for: "[check_password_breach]" log messages
```

## UI Elements to Verify

### When Compromised:
- [ ] Red warning card with border
- [ ] Warning icon (⚠️)
- [ ] "🚨 Password Compromised!" title
- [ ] Breach count displayed
- [ ] Description text visible
- [ ] "Get Security Tips" button (shows snackbar on click)

### When Safe:
- [ ] Green checkmark icon
- [ ] "Good news!" header
- [ ] "No breaches found for this password" message
- [ ] Security recommendations visible

### Form Elements:
- [ ] Password field has obscured text
- [ ] Hint text visible before typing
- [ ] Icon changes between email/password tabs
- [ ] Label text updates correctly
- [ ] Form validation works

## Performance Notes

- First request may take 1-2 seconds (Django startup)
- Subsequent requests should be under 200ms
- No network requests should fail for valid API setup

## Backend Logs

When testing, check Django console for:
```
[check_password_breach] Password: pass***, Compromised: True, Count: 3547661
```

This confirms the endpoint is being called and processed correctly.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Backend not configured" | Set IP in app settings (IP menu button) |
| App crashes | Check Flutter logs: `flutter logs` |
| API returns 404 | Verify URL in urls.py includes the endpoint |
| Always returns compromised=false | Check password is in COMPROMISED_PASSWORDS list |
| Wrong breach count | Verify BREACH_COUNTS dictionary in views.py |

## Success Criteria

✅ Feature is complete when:
1. App successfully switches between Email and Password tabs
2. Password input field shows asterisks/dots
3. Common passwords show as compromised
4. Unique passwords show as safe
5. Red warning displays for compromised passwords
6. Green success displays for safe passwords
7. Django logs show endpoint being called
8. No Flutter errors or warnings
