# Django Permission Demo

Minimal Django project that exposes an endpoint to list a user's permissions.

Quickstart

1. Create and activate a virtualenv (recommended).

2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Run migrations and create a superuser:

```bash
python manage.py migrate
python manage.py createsuperuser
```

4. Run the development server:

```bash
python manage.py runserver
```

5. Query permissions (replace `alice` with an existing username):

```bash
curl http://127.0.0.1:8000/permissions/alice/
```
