import 'package:flutter/material.dart';

class AnalysisResult {
  final String packageName;
  final List<String> grantedPermissions;
  final int permissionCount;
  final int riskScore;
  final String riskLevel;
  final List<int> binaryVector;
  final String? prediction;
  final double? confidence;

  AnalysisResult({
    required this.packageName,
    required this.grantedPermissions,
    required this.permissionCount,
    required this.riskScore,
    required this.riskLevel,
    required this.binaryVector,
    this.prediction,
    this.confidence,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      packageName: json['packageName'] ?? '',
      grantedPermissions: List<String>.from(json['granted_permissions'] ?? []),
      permissionCount: json['permission_count'] ?? 0,
      riskScore: json['risk_score'] ?? 0,
      riskLevel: json['risk_level'] ?? 'unknown',
      binaryVector: List<int>.from(json['binary_vector'] ?? []),
      prediction: json['prediction'],
      confidence: json['confidence'] is num
          ? (json['confidence'] as num).toDouble()
          : null,
    );
  }
}

class AnalysisResultsPage extends StatelessWidget {
  final List<AnalysisResult> results;

  const AnalysisResultsPage({super.key, required this.results});

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPredictionColor(String? prediction) {
    if (prediction == null) return Colors.grey;
    return prediction.toLowerCase() == 'malware' ? Colors.red : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Results'), elevation: 0),
      body: results.isEmpty
          ? const Center(child: Text('No analysis results available'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                return _buildResultCard(context, result);
              },
            ),
    );
  }

  Widget _buildResultCard(BuildContext context, AnalysisResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getRiskColor(result.riskLevel), width: 2),
      ),
      child: Column(
        children: [
          // Header with app name and risk level
          Container(
            decoration: BoxDecoration(
              color: _getRiskColor(result.riskLevel).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.packageName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRiskColor(result.riskLevel),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          result.riskLevel.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Details section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Risk Score
                _buildDetailRow(
                  'Risk Score',
                  '${result.riskScore}/100',
                  Icons.warning_amber_rounded,
                ),
                const SizedBox(height: 16),

                // Permission Count
                _buildDetailRow(
                  'Permissions Granted',
                  result.permissionCount.toString(),
                  Icons.vpn_lock,
                ),
                const SizedBox(height: 16),

                // Malware Prediction
                if (result.prediction != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getPredictionColor(
                        result.prediction,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getPredictionColor(result.prediction),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              result.prediction == 'malware'
                                  ? Icons.dangerous
                                  : Icons.verified_user,
                              color: _getPredictionColor(result.prediction),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prediction',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  result.prediction!.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getPredictionColor(
                                      result.prediction,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (result.confidence != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Confidence',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${result.confidence!.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Granted Permissions List
                if (result.grantedPermissions.isNotEmpty) ...[
                  const Text(
                    'Granted Permissions',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: result.grantedPermissions
                          .map(
                            (perm) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatPermissionName(perm),
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'No permissions granted',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),

          // Suggestions Section
          _buildSuggestionsSection(result),

          // Expand button to show binary vector
          ExpansionTile(
            title: const Text(
              'Technical Details',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Binary Vector (Permissions Encoded):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          result.binaryVector.join(''),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPermissionName(String permission) {
    // Remove 'android.permission.' prefix if present
    String name = permission.replaceAll('android.permission.', '');
    // Convert UPPER_CASE to Title Case
    return name
        .split('_')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  List<String> _generateSuggestions(AnalysisResult result) {
    List<String> suggestions = [];

    // Risk-based suggestions
    if (result.riskScore >= 80) {
      suggestions.add(
        '⚠️ Critical Risk: Consider uninstalling this app or reviewing its permissions immediately',
      );
    } else if (result.riskScore >= 60) {
      suggestions.add(
        '⚠️ High Risk: Review the permissions and consider restricting access to sensitive data',
      );
    } else if (result.riskScore >= 40) {
      suggestions.add(
        'ℹ️ Medium Risk: Monitor this app\'s behavior and restrict permissions if unnecessary',
      );
    }

    // Malware-based suggestions
    if (result.prediction == 'malware' && result.confidence != null) {
      if (result.confidence! >= 80) {
        suggestions.add(
          '🚨 Malware Alert: This app shows strong malware characteristics. Uninstall immediately',
        );
      } else if (result.confidence! >= 60) {
        suggestions.add(
          '⚠️ Potential Malware: This app has suspicious characteristics. Consider uninstalling',
        );
      }
    }

    // Permission-based suggestions
    final dangerousPerms = [
      'CAMERA',
      'RECORD_AUDIO',
      'ACCESS_FINE_LOCATION',
      'READ_CONTACTS',
      'READ_CALL_LOG',
      'READ_SMS',
      'SEND_SMS',
      'WRITE_SECURE_SETTINGS',
      'INSTALL_PACKAGES',
    ];

    final hasDANGEROUS = result.grantedPermissions.any(
      (perm) => dangerousPerms.any((d) => perm.contains(d)),
    );

    if (hasDANGEROUS) {
      suggestions.add(
        '📱 Sensitive Permissions: This app has access to camera, microphone, or location data',
      );
    }

    if (result.permissionCount > 15) {
      suggestions.add(
        '📊 High Permission Count: This app requests many permissions. Consider if all are necessary',
      );
    }

    // Default suggestion if no issues
    if (suggestions.isEmpty) {
      suggestions.add(
        '✅ App Risk Profile: This app appears relatively safe based on current analysis',
      );
    }

    return suggestions;
  }

  Widget _buildSuggestionsSection(AnalysisResult result) {
    final suggestions = _generateSuggestions(result);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Suggestions & Recommendations',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: suggestions
                .map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
