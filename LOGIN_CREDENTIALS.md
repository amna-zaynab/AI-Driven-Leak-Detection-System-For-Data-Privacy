# Valid Test Credentials

The following user accounts are available in the database for testing the login functionality:

## Test Users

| Email | Password | Name | Phone |
|-------|----------|------|-------|
| z@gmail.com | Admin@123 | zabu | 9632580741 |
| a@gmail.com | Admin@123 | alice | (not set) |
| u@gmail.com | Admin123 | user | (not set) |

## Login Testing

### Using Flutter App:
1. Make sure the Django backend is running at your configured IP
2. Enter one of the email addresses above
3. Enter the corresponding password
4. Click "Sign In"

### Using cURL (Backend Testing):
```bash
curl -X POST http://localhost:8000/api/login/ \
  -H "Content-Type: application/json" \
  -d '{"email": "z@gmail.com", "password": "Admin@123"}'
```

### Expected Response (Success - 200):
```json
{
  "success": true,
  "message": "Login successful",
  "user_id": 3,
  "email": "z@gmail.com",
  "name": "zabu",
  "phone": "9632580741"
}
```

## Troubleshooting

### "Invalid email or password" Error
1. **Check the email**: Ensure you're using the exact email from the table above
2. **Check the password**: Passwords are case-sensitive. Verify character by character
3. **Check spacing**: Avoid leading/trailing spaces in email and password fields
4. **Backend status**: Ensure Django is running at the correct URL

### Connection Error
1. **Network connection**: Check if the backend server is accessible
2. **IP Address**: Verify the backend IP in the app settings matches your server
3. **Port**: Ensure port 8000 is open and accessible
4. **CORS**: Backend should have CORS headers configured

## Notes

- Passwords are stored in plain text in the database (not recommended for production)
- For production, implement proper password hashing with bcrypt or Django's password hashing
- User data is stored in the `UserProfile` model in `api/models.py`
