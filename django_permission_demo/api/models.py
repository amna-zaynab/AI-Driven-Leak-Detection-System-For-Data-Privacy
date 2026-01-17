

from django.db import models

# Model for user login
class Login(models.Model):
	username = models.CharField(max_length=100)
	password = models.CharField(max_length=100)
	usertype = models.CharField(max_length=100)

# Model to store user profile information
class UserProfile(models.Model):
	name = models.CharField(max_length=255)
	email = models.EmailField(unique=True, max_length=255)
	phone = models.CharField(max_length=20, blank=True, null=True)
	password = models.CharField(max_length=255)
	created_at = models.DateTimeField(auto_now_add=True)
	updated_at = models.DateTimeField(auto_now=True)
	is_active = models.BooleanField(default=True)

	class Meta:
		ordering = ['-created_at']
		indexes = [
			models.Index(fields=['email']),
		]

	def __str__(self):
		return f"{self.name} ({self.email})"

# Model to match the app_patterns table
class AppPatterns(models.Model):
	appname = models.CharField(max_length=200, blank=True, null=True)
	permsissionpattern = models.CharField(max_length=5000, blank=True, null=True)
	type = models.CharField(max_length=50, blank=True, null=True)

# Model to store phishing URL history
class PhishingUrlHistory(models.Model):
	RISK_LEVEL_CHOICES = [
		('safe', 'Safe'),
		('suspicious', 'Suspicious'),
		('phishing', 'Phishing'),
		('malware', 'Malware'),
	]
	
	url = models.URLField(max_length=500)
	risk_level = models.CharField(max_length=20, choices=RISK_LEVEL_CHOICES, default='safe', blank=True, null=True)
	is_phishing = models.BooleanField(default=False)
	confidence_score = models.FloatField(default=0.0, blank=True, null=True)
	details = models.TextField(blank=True, null=True)
	threats = models.JSONField(default=list, blank=True)
	detected_at = models.DateTimeField(auto_now_add=True)
	user = models.CharField(max_length=100, blank=True, null=True)
	
	class Meta:
		ordering = ['-detected_at']
		indexes = [
			models.Index(fields=['url']),
			models.Index(fields=['user', '-detected_at']),
		]

# Model to store app history with permission analysis
class AppHistory(models.Model):
	packageName = models.CharField(max_length=300, blank=True, null=True)
	app_name = models.CharField(max_length=200, blank=True, null=True)
	action = models.CharField(max_length=100, blank=True, null=True)
	granted_permissions = models.JSONField(default=list, blank=True)
	permission_count = models.IntegerField(default=0, blank=True, null=True)
	risk_score = models.IntegerField(default=0, blank=True, null=True)
	risk_level = models.CharField(max_length=20, blank=True, null=True)
	binary_vector = models.JSONField(default=list, blank=True)
	prediction = models.CharField(max_length=50, blank=True, null=True)
	confidence = models.FloatField(default=0.0, blank=True, null=True)
	suggestion = models.TextField(blank=True, null=True)
	timestamp = models.DateTimeField(auto_now_add=True)
	user = models.CharField(max_length=100, blank=True, null=True)

# Model to store leak detection history
class LeakDetectionHistory(models.Model):
	leak_type = models.CharField(max_length=200)
	details = models.TextField()
	detected_at = models.DateTimeField(auto_now_add=True)
	user = models.CharField(max_length=100, blank=True, null=True)
# Model to store breach detection history
class BreachHistory(models.Model):
	email = models.EmailField(max_length=255)
	breach_name = models.CharField(max_length=200)
	breach_domain = models.CharField(max_length=255, blank=True, null=True)
	breach_date = models.DateField(blank=True, null=True)
	description = models.TextField(blank=True, null=True)
	pwn_count = models.BigIntegerField(default=0, blank=True, null=True)
	is_verified = models.BooleanField(default=False)
	is_sensitive = models.BooleanField(default=False)
	is_active = models.BooleanField(default=True)
	is_retired = models.BooleanField(default=False)
	is_spam_list = models.BooleanField(default=False)
	is_malware_list = models.BooleanField(default=False)
	is_subscription_free = models.BooleanField(default=True)
	logo_path = models.URLField(max_length=500, blank=True, null=True)
	data_classes = models.TextField(blank=True, null=True)
	detected_at = models.DateTimeField(auto_now_add=True)
	user = models.CharField(max_length=100, blank=True, null=True)

	class Meta:
		ordering = ['-detected_at']
		indexes = [
			models.Index(fields=['email', '-detected_at']),
			models.Index(fields=['user', '-detected_at']),
		]

# Model to store phone number breach detection history
class PhoneBreachHistory(models.Model):
	phone = models.CharField(max_length=20)
	breach_name = models.CharField(max_length=200)
	breach_domain = models.CharField(max_length=255, blank=True, null=True)
	breach_date = models.DateField(blank=True, null=True)
	description = models.TextField(blank=True, null=True)
	detected_at = models.DateTimeField(auto_now_add=True)
	user = models.CharField(max_length=100, blank=True, null=True)

	class Meta:
		ordering = ['-detected_at']
		indexes = [
			models.Index(fields=['phone', '-detected_at']),
			models.Index(fields=['user', '-detected_at']),
		]