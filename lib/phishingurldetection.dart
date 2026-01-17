import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeakDetectionPage extends StatefulWidget {
  const LeakDetectionPage({super.key});

  @override
  State<LeakDetectionPage> createState() => _LeakDetectionPageState();
}

class _LeakDetectionPageState extends State<LeakDetectionPage> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;
  List<Map<String, dynamic>> _history = [];
  bool _showHistory = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_email') ?? '';
      final baseUrl = prefs.getString('ip') ?? '';

      if (baseUrl.isEmpty) {
        setState(() {
          _error = 'Server URL not configured';
          _loading = false;
        });
        return;
      }

      final uri = Uri.parse('$baseUrl/api/check_phishing_url/');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': url, 'user': username}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle the backend response format
        if (data['success'] == true) {
          setState(() {
            _result = {
              'url': data['url'],
              'is_phishing': data['is_phishing'],
              'risk_level': data['risk_level'],
              'confidence_score': data['confidence_score'],
              'details': data['reason'] ?? 'No details provided', // Map 'reason' to 'details'
              'threats': [], // Backend doesn't provide threats yet
            };
            _urlController.clear();
          });
          // Refresh history after check
          await _loadHistory();
        } else {
          setState(() {
            _error = data['error'] ?? 'Unknown error occurred';
          });
        }
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _error = 'Error: ${errorData['error'] ?? response.statusCode}';
        });
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

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_email') ?? '';
      final baseUrl = prefs.getString('ip') ?? '';

      if (username.isEmpty || baseUrl.isEmpty) return;

      final uri = Uri.parse(
        '$baseUrl/api/get_phishing_history/?user=$username',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _history = List<Map<String, dynamic>>.from(data['records'] ?? []);
        });
      } else {
        final errorData = json.decode(response.body);
        print('Error loading history: ${errorData['error']}');
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'safe':
        return Colors.green;
      case 'suspicious':
        return Colors.orange;
      case 'phishing':
        return Colors.red;
      case 'malware':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'safe':
        return Icons.shield_outlined;
      case 'suspicious':
        return Icons.warning_amber;
      case 'phishing':
        return Icons.error_outline;
      case 'malware':
        return Icons.coronavirus;
      default:
        return Icons.help_outline;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Phishing URL Detector'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showHistory = !_showHistory;
                  });
                },
                child: Text(
                  _showHistory ? 'Check URL' : 'History',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_showHistory) ...[
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
                          const Text(
                            'Enter a URL to check if it\'s a phishing attempt. The detector analyzes the URL for suspicious patterns, keywords, and characteristics commonly found in phishing and malware URLs.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // URL Input Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter URL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _urlController,
                          keyboardType: TextInputType.url,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'https://example.com',
                            hintStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(
                              Icons.link,
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
                            if (v == null || v.trim().isEmpty) {
                              return 'URL required';
                            }
                            if (!v.startsWith('http://') &&
                                !v.startsWith('https://')) {
                              return 'URL must start with http:// or https://';
                            }
                            return null;
                          },
                        ),
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
                          _checkUrl();
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security_outlined),
                          SizedBox(width: 8),
                          Text(
                            'Check URL',
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

                  // Results
                  if (_result != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getRiskColor(
                          _result!['risk_level'],
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getRiskColor(_result!['risk_level']),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Risk Badge
                          Row(
                            children: [
                              Icon(
                                _getRiskIcon(_result!['risk_level']),
                                color: _getRiskColor(_result!['risk_level']),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _result!['risk_level']
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: _getRiskColor(
                                          _result!['risk_level'],
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Confidence: ${(_result!['confidence_score'] * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: _getRiskColor(
                                          _result!['risk_level'],
                                        ).withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // URL
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'URL:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _result!['url'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Details
                          Text(
                            'Details:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _result!['details'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),

                          // Is Phishing Indicator
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _result!['is_phishing']
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _result!['is_phishing']
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _result!['is_phishing']
                                      ? Icons.dangerous
                                      : Icons.verified,
                                  color: _result!['is_phishing']
                                      ? Colors.red
                                      : Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _result!['is_phishing']
                                      ? 'PHISHING DETECTED'
                                      : 'SAFE URL',
                                  style: TextStyle(
                                    color: _result!['is_phishing']
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (!_loading && _error == null) ...[
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Colors.blueGrey[400],
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No URL checked yet',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // History View
                  const Text(
                    'Check History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_history.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.blueGrey[400],
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No history',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final record = _history[i];
                        return Card(
                          color: const Color(0xFF121828),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getRiskIcon(record['risk_level']),
                                      color: _getRiskColor(
                                        record['risk_level'],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record['url'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Risk: ${record['risk_level']} (${(record['confidence_score'] * 100).toStringAsFixed(0)}%)',
                                            style: TextStyle(
                                              color: _getRiskColor(
                                                record['risk_level'],
                                              ),
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Date: ${DateTime.parse(record['detected_at']).toLocal().toString().split(' ')[0]}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}