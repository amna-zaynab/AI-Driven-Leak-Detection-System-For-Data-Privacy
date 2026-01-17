import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmailBreachPage extends StatefulWidget {
  const EmailBreachPage({super.key});

  @override
  State<EmailBreachPage> createState() => _EmailBreachPageState();
}

class _EmailBreachPageState extends State<EmailBreachPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  List<Map<String, dynamic>> _breaches = [];
  String? _error;
  bool _hasBreaches = false;
  String _searchType = 'email'; // 'email' or 'password'
  bool _passwordVisible = false;

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'medium':
        return Colors.amber[700]!;
      case 'low':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Future<void> _checkBreaches() async {
    final value = _searchType == 'email'
        ? _emailController.text.trim()
        : _passwordController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      _loading = true;
      _breaches = [];
      _error = null;
      _hasBreaches = false;
    });

    try {
      if (_searchType == 'email') {
        await _checkEmailBreaches(value);
      } else {
        await _checkPasswordBreach(value);
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _checkEmailBreaches(String email) async {
    try {
      final uri = Uri.parse(
        'https://haveibeenpwned.com/api/v3/breachedaccount/${Uri.encodeComponent(email)}',
      );

      final resp = await http.get(
        uri,
        headers: {
          'hibp-api-key': '042e5c01217041c780a512b4dd3dd7af',
          'user-agent': 'privacy-app/1.0',
        },
      );

      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        // Display all breaches to user
        final allBreaches = data.map((e) => e as Map<String, dynamic>).toList();

        // Store only first 10 breaches to server
        final breachesToStore = allBreaches.take(10).toList();

        setState(() {
          _breaches = allBreaches;
          _hasBreaches = true;
        });

        // Store first 10 breaches to server only
        for (final breach in breachesToStore) {
          await _storeBreachInBackend(email, breach, 'email');
        }
      } else if (resp.statusCode == 404) {
        setState(() {
          _hasBreaches = false;
        });
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        final sampleBreaches = [
          {
            'Name': 'Adobe',
            'Domain': 'adobe.com',
            'BreachDate': '2013-10-04',
            'PwnCount': 153000000,
            'IsVerified': true,
            'IsSensitive': false,
            'IsActive': true,
            'IsRetired': false,
            'IsSpamList': false,
            'IsMalwareList': false,
            'IsSubscriptionFree': true,
            'LogoPath':
                'https://haveibeenpwned.com/Content/Logos/Breaches/adobe.png',
            'DataClasses': [
              'Usernames',
              'Passwords',
              'Password hints',
              'Email addresses',
              'Security questions and answers',
            ],
            'Description':
                'In October 2013, 153 million Adobe accounts were breached with each containing an internal ID, username, email, encrypted password and a password hint in plain text.',
          },
          {
            'Name': 'LinkedIn',
            'Domain': 'linkedin.com',
            'BreachDate': '2012-05-05',
            'PwnCount': 164000000,
            'IsVerified': true,
            'IsSensitive': false,
            'IsActive': true,
            'IsRetired': false,
            'IsSpamList': false,
            'IsMalwareList': false,
            'IsSubscriptionFree': true,
            'LogoPath':
                'https://haveibeenpwned.com/Content/Logos/Breaches/linkedin.png',
            'DataClasses': [
              'Email addresses',
              'Passwords',
              'Profile information',
            ],
            'Description':
                'In May 2016, LinkedIn had 164 million email addresses and passwords exposed. Originally hacked in 2012, the data remained out of sight until being offered for sale on a dark market site four years later.',
          },
          {
            'Name': 'MySpace',
            'Domain': 'myspace.com',
            'BreachDate': '2008-01-01',
            'PwnCount': 360000000,
            'IsVerified': true,
            'IsSensitive': false,
            'IsActive': true,
            'IsRetired': false,
            'IsSpamList': false,
            'IsMalwareList': false,
            'IsSubscriptionFree': true,
            'LogoPath':
                'https://haveibeenpwned.com/Content/Logos/Breaches/myspace.png',
            'DataClasses': ['Email addresses', 'Passwords', 'Usernames'],
            'Description':
                'In approximately 2008, Myspace suffered a data breach that affected 360 million user accounts. The data was later made freely available on the Internet in 2016.',
          },
          {
            'Name': 'Yahoo',
            'Domain': 'yahoo.com',
            'BreachDate': '2013-08-24',
            'PwnCount': 3000000000,
            'IsVerified': true,
            'IsSensitive': false,
            'IsActive': true,
            'IsRetired': false,
            'IsSpamList': false,
            'IsMalwareList': false,
            'IsSubscriptionFree': true,
            'LogoPath':
                'https://haveibeenpwned.com/Content/Logos/Breaches/yahoo.png',
            'DataClasses': [
              'Emails',
              'Passwords',
              'Phone numbers',
              'Date of birth',
              'Security questions',
            ],
            'Description':
                'In 2013, Yahoo disclosed that 3 billion accounts had been breached. The data included emails, passwords, phone numbers, dates of birth and security questions and answers.',
          },
          {
            'Name': 'Facebook',
            'Domain': 'facebook.com',
            'BreachDate': '2019-04-03',
            'PwnCount': 533000000,
            'IsVerified': true,
            'IsSensitive': false,
            'IsActive': true,
            'IsRetired': false,
            'IsSpamList': false,
            'IsMalwareList': false,
            'IsSubscriptionFree': true,
            'LogoPath':
                'https://haveibeenpwned.com/Content/Logos/Breaches/facebook.png',
            'DataClasses': [
              'Phone numbers',
              'Email addresses',
              'Names',
              'User IDs',
            ],
            'Description':
                'In 2019, 533 million Facebook user records were found on third-party servers. The data included names, phone numbers, email addresses, and user IDs.',
          },
          {
            'Name': 'Equifax',
            'Domain': 'equifax.com',
            'BreachDate': '2017-05-13',
            'PwnCount': 147000000,
            'IsVerified': true,
            'IsSensitive': true,
            'IsActive': true,
            'IsRetired': false,
            'IsSpamList': false,
            'IsMalwareList': false,
            'IsSubscriptionFree': false,
            'LogoPath':
                'https://haveibeenpwned.com/Content/Logos/Breaches/equifax.png',
            'DataClasses': [
              'Social Security numbers',
              'Credit card data',
              'Personal information',
              'Dates of birth',
              'Addresses',
            ],
            'Description':
                'Equifax, one of the largest credit reporting agencies, suffered a massive data breach affecting 147 million individuals. The breach exposed sensitive personal and financial information.',
          },
          {
            'Name': 'Uber',
            'Domain': 'uber.com',
            'BreachDate': '2016-11-27',
            'PwnCount': 57000000,
            'IsVerified': true,
            'IsSensitive': false,
            'IsActive': true,
            'IsRetired': false,
            'IsSpamList': false,
            'IsMalwareList': false,
            'IsSubscriptionFree': true,
            'LogoPath':
                'https://haveibeenpwned.com/Content/Logos/Breaches/uber.png',
            'DataClasses': ['Email addresses', 'Names', 'Phone numbers'],
            'Description':
                'Uber suffered a breach that exposed the personal information of 57 million users and drivers, including names, email addresses and phone numbers.',
          },
          {
            'Name': 'Twitter',
            'Domain': 'twitter.com',
            'BreachDate': '2022-08-04',
            'PwnCount': 5600000,
            'IsVerified': true,
            'IsSensitive': false,
            'IsActive': true,
            'IsRetired': false,
            'IsSpamList': false,
            'IsMalwareList': false,
            'IsSubscriptionFree': true,
            'LogoPath':
                'https://haveibeenpwned.com/Content/Logos/Breaches/twitter.png',
            'DataClasses': ['Email addresses', 'Phone numbers', 'Usernames'],
            'Description':
                'A vulnerability in Twitter was exploited to expose email addresses and phone numbers for millions of users.',
          },
          {
            'Name': 'Twitch',
            'Domain': 'twitch.tv',
            'BreachDate': '2021-06-22',
            'PwnCount': 4000000,
            'IsVerified': true,
            'IsSensitive': false,
            'IsActive': true,
            'IsRetired': false,
            'IsSpamList': false,
            'IsMalwareList': false,
            'IsSubscriptionFree': true,
            'LogoPath':
                'https://haveibeenpwned.com/Content/Logos/Breaches/twitch.png',
            'DataClasses': ['Usernames', 'Email addresses', 'Password hashes'],
            'Description':
                'Twitch suffered a data breach that exposed usernames, email addresses and password hashes for millions of users and streamers.',
          },
          {
            'Name': 'Instagram',
            'Domain': 'instagram.com',
            'BreachDate': '2022-01-10',
            'PwnCount': 6300000,
            'IsVerified': true,
            'IsSensitive': false,
            'IsActive': true,
            'IsRetired': false,
            'IsSpamList': false,
            'IsMalwareList': false,
            'IsSubscriptionFree': true,
            'LogoPath':
                'https://haveibeenpwned.com/Content/Logos/Breaches/instagram.png',
            'DataClasses': [
              'Usernames',
              'Email addresses',
              'Phone numbers',
              'User IDs',
            ],
            'Description':
                'A security issue exposed the email addresses and phone numbers associated with Instagram accounts. This data could be used for targeted attacks.',
          },
        ];

        setState(() {
          _error =
              'API key missing or invalid. Please obtain a valid API key from haveibeenpwned.com. For demo purposes, sample breaches are shown.';
          _breaches = sampleBreaches;
          _hasBreaches = true;
        });

        // Store only first 10 sample breaches to server
        for (final breach in sampleBreaches.take(10)) {
          await _storeBreachInBackend(email, breach, 'email');
        }
      } else if (resp.statusCode == 429) {
        setState(() {
          _error = 'Too many requests. Please try again later.';
        });
      } else {
        setState(() {
          _error = 'Error ${resp.statusCode}: ${resp.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _checkPasswordBreach(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('ip');

      if (baseUrl == null || baseUrl.isEmpty) {
        setState(() {
          _error =
              'Backend server not configured. Please check your server IP settings.';
          _hasBreaches = false;
        });
        return;
      }

      final uri = Uri.parse('$baseUrl/api/check_password_breach/');

      print('Checking password breach for: $password');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );

      print('Password breach check response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['is_compromised'] == true) {
          final breachCount = data['count'] ?? 0;
          setState(() {
            _error =
                'This password has been found in $breachCount known data breaches. Please change it immediately!';
            _hasBreaches = true;
            _breaches = [
              {
                'message': 'Password Compromised',
                'description':
                    'This password appears in known password breach databases. It should be changed immediately.',
                'count': breachCount,
                'severity': 'CRITICAL',
              },
            ];
          });
        } else {
          setState(() {
            _hasBreaches = false;
            _error = null;
            _breaches = [];
          });
        }
      } else if (response.statusCode == 400) {
        setState(() {
          _error = 'Invalid password format. Please enter a valid password.';
          _hasBreaches = false;
        });
      } else {
        setState(() {
          _error = 'Error checking password: ${response.statusCode}';
          _hasBreaches = false;
        });
      }
    } catch (e) {
      print('Password breach check error: $e');
      setState(() {
        _error = 'Error checking password: ${e.toString()}';
        _hasBreaches = false;
      });
    }
  }

  Future<void> _storeBreachInBackend(
    String identifier,
    Map<String, dynamic> breach,
    String type,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_email') ?? 'anonymous';
      final baseUrl = prefs.getString('ip');

      if (baseUrl == null || baseUrl.isEmpty) {
        print(
          'Warning: Backend IP not configured, skipping storage of $type breach',
        );
        return;
      }

      final endpoint = type == 'email' ? 'store_breach' : 'store_phone_breach';
      final uri = Uri.parse('$baseUrl/api/$endpoint/');

      print('Storing $type breach to: $uri');

      final body = type == 'email'
          ? {
              'email': identifier,
              'breach_name': breach['Name'] ?? '',
              'breach_domain': breach['Domain'] ?? '',
              'breach_date': breach['BreachDate'] ?? '',
              'description': breach['Description'] ?? '',
              'pwn_count': breach['PwnCount'] ?? 0,
              'is_verified': breach['IsVerified'] ?? false,
              'is_sensitive': breach['IsSensitive'] ?? false,
              'is_active': breach['IsActive'] ?? true,
              'is_retired': breach['IsRetired'] ?? false,
              'is_spam_list': breach['IsSpamList'] ?? false,
              'is_malware_list': breach['IsMalwareList'] ?? false,
              'is_subscription_free': breach['IsSubscriptionFree'] ?? true,
              'logo_path': breach['LogoPath'] ?? '',
              'data_classes': breach['DataClasses'] != null
                  ? (breach['DataClasses'] is List
                        ? breach['DataClasses'].join(',')
                        : breach['DataClasses'].toString())
                  : '',
              'user': username,
            }
          : {
              'phone': identifier,
              'breach_name': breach['Name'] ?? '',
              'breach_domain': breach['Domain'] ?? '',
              'breach_date': breach['BreachDate'] ?? '',
              'description': breach['Description'] ?? '',
              'user': username,
            };

      print('Request body: $body');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        print('${type.toUpperCase()} breach stored successfully in backend');
      } else {
        print(
          'Failed to store $type breach: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error storing $type breach in backend: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Breach Checker'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle between Email and Phone
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121828),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueGrey[700]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchType = 'email';
                              _breaches = [];
                              _error = null;
                              _hasBreaches = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _searchType == 'email'
                                  ? Colors.blue[700]
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: _searchType == 'email'
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    color: _searchType == 'email'
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: _searchType == 'email'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchType = 'password';
                              _breaches = [];
                              _error = null;
                              _hasBreaches = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _searchType == 'password'
                                  ? Colors.blue[700]
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.vpn_key,
                                  color: _searchType == 'password'
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    color: _searchType == 'password'
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: _searchType == 'password'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Information Card
                Card(
                  color: const Color(0xFF121828),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[300]),
                            const SizedBox(width: 8),
                            const Text(
                              'How it works',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchType == 'email'
                              ? 'Check if your email has been involved in known data breaches. This demo uses sample data. For real checks, obtain an API key from haveibeenpwned.com.'
                              : 'Check if your password has been compromised in known data breaches. Your password is checked securely against our database.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email/Phone Input Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _searchType == 'email' ? 'Email Address' : 'Password',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_searchType == 'email') ...[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'you@example.com',
                            hintStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF121828),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blueGrey[700]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue[400]!),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Email required';
                            final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            );
                            if (!emailRegex.hasMatch(v))
                              return 'Enter a valid email';
                            return null;
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          keyboardType: TextInputType.visiblePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(
                              Icons.vpn_key_outlined,
                              color: Colors.white70,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFF121828),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blueGrey[700]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue[400]!),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Password required';
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Check Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _checkBreaches();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search),
                              const SizedBox(width: 8),
                              Text(
                                'Check for Breaches',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Loading Indicator
                if (_loading) ...[
                  LinearProgressIndicator(
                    backgroundColor: Colors.blueGrey[800],
                    color: Colors.blue[400],
                    minHeight: 3,
                  ),
                  const SizedBox(height: 16),
                ],

                // Error Message
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[900]!.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[700]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[300]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red[300]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Results Section
                if (_breaches.isEmpty && !_loading && _error == null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.blueGrey[400],
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No checks performed yet',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Enter your ${_searchType == 'email' ? 'email' : 'password'} above to check for breaches',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_hasBreaches && _breaches.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // For password breaches, show simplified warning
                      if (_searchType == 'password') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[900]!.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red[700]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    color: Colors.red[400],
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '🚨 Password Compromised!',
                                          style: TextStyle(
                                            color: Color(0xFFFF6B6B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _breaches.isNotEmpty
                                              ? 'Found in ${_breaches[0]['count']} known breaches'
                                              : 'Found in multiple breaches',
                                          style: TextStyle(
                                            color: Colors.red[300],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: Colors.red[700], height: 1),
                              const SizedBox(height: 12),
                              Text(
                                _breaches[0]['description'] ??
                                    'This password has been found in public data breaches and should be changed immediately.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Navigate to password manager or security tips
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '🔐 Use a password manager and create a strong, unique password',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.security),
                                  label: const Text('Get Security Tips'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                      // For email breaches, show detailed list
                      else ...[
                        // Results Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[900]!.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[700]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.orange[300],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⚠️ Email found in ${_breaches.length} breach${_breaches.length > 1 ? 'es' : ''}',
                                      style: TextStyle(
                                        color: Colors.orange[300],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Take immediate action to secure your account',
                                      style: TextStyle(
                                        color: Colors.orange[300],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Breach List
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _breaches.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final breach = _breaches[i];
                            return Card(
                              color: const Color(0xFF121828),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Breach Title with Severity Badge
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.report_gmailerrorred,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            breach['Name'] ?? 'Unknown Breach',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (breach['Severity'] != null) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getSeverityColor(
                                                breach['Severity'],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              breach['Severity'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Divider
                                    Divider(color: Colors.white12, height: 1),
                                    const SizedBox(height: 12),

                                    // Domain
                                    if (breach['Domain'] != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.language,
                                            color: Colors.blue[300],
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Domain',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                breach['Domain'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    // Breach Date
                                    if (breach['BreachDate'] != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Colors.red[300],
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Breach Date',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                breach['BreachDate'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    // Compromised Data
                                    if (breach['DataClasses'] != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.data_usage,
                                            color: Colors.yellow[600],
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Compromised Data',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 250,
                                                child: Text(
                                                  (breach['DataClasses']
                                                          as List)
                                                      .join(', '),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    // Description
                                    if (breach['Description'] != null) ...[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.description,
                                            color: Colors.green[300],
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Details',
                                                  style: TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  breach['Description'],
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    // Additional Breach Info
                                    if (breach['PwnCount'] != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people,
                                            color: Colors.purple[300],
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Affected Accounts',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                '${breach['PwnCount'] ?? 'Unknown'} accounts',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],

                                    // Action Required Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[900]!.withOpacity(
                                          0.3,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.orange[700]!,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.warning_amber,
                                            color: Colors.orange[300],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Action Required',
                                            style: TextStyle(
                                              color: Colors.orange[300],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  )
                else if (!_hasBreaches && !_loading)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green[400],
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Good news!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No breaches found for this ${_searchType == 'email' ? 'email address' : 'password'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Continue using strong passwords and enabling 2FA',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
