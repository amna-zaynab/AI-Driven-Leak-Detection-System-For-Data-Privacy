import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppScan {
  final String packageName;
  final String appName;
  final DateTime scanDate;
  final int riskScore;
  final String riskLevel;
  final String? prediction;

  AppScan({
    required this.packageName,
    required this.appName,
    required this.scanDate,
    required this.riskScore,
    required this.riskLevel,
    this.prediction,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'scanDate': scanDate.toIso8601String(),
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'prediction': prediction,
    };
  }

  factory AppScan.fromJson(Map<String, dynamic> json) {
    return AppScan(
      packageName: json['packageName'] ?? '',
      appName: json['appName'] ?? '',
      scanDate: DateTime.parse(
        json['scanDate'] ?? DateTime.now().toIso8601String(),
      ),
      riskScore: json['riskScore'] ?? 0,
      riskLevel: json['riskLevel'] ?? 'unknown',
      prediction: json['prediction'],
    );
  }
}

class AppHistoryService {
  static const String _scanHistoryKey = 'app_scan_history';
  static const String _privacyScoreKey = 'privacy_score';
  static const String _privacyScoreDateKey = 'privacy_score_date';

  // Add a scan to history
  static Future<void> addScan(AppScan scan) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getAllScans();

    // Check if app already exists in history
    final existingIndex = history.indexWhere(
      (s) => s.packageName == scan.packageName,
    );
    if (existingIndex >= 0) {
      history[existingIndex] = scan;
    } else {
      history.add(scan);
    }

    // Keep only last 100 scans
    if (history.length > 100) {
      history.removeRange(0, history.length - 100);
    }

    final jsonList = history.map((scan) => json.encode(scan.toJson())).toList();
    await prefs.setStringList(_scanHistoryKey, jsonList);
  }

  // Get all scans
  static Future<List<AppScan>> getAllScans() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_scanHistoryKey) ?? [];

    return jsonList
        .map((jsonStr) {
          try {
            return AppScan.fromJson(
              json.decode(jsonStr) as Map<String, dynamic>,
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<AppScan>()
        .toList();
  }

  // Get unique scanned apps count
  static Future<int> getScannedAppsCount() async {
    final scans = await getAllScans();
    return scans.length;
  }

  // Set privacy score
  static Future<void> setPrivacyScore(double score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_privacyScoreKey, score);
    await prefs.setString(
      _privacyScoreDateKey,
      DateTime.now().toIso8601String(),
    );
  }

  // Get privacy score
  static Future<double?> getPrivacyScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_privacyScoreKey);
  }

  // Get privacy score update date
  static Future<DateTime?> getPrivacyScoreDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_privacyScoreDateKey);
    if (dateStr == null) return null;
    return DateTime.parse(dateStr);
  }

  // Clear all history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scanHistoryKey);
  }

  // Get high-risk apps
  static Future<List<AppScan>> getHighRiskApps() async {
    final scans = await getAllScans();
    return scans.where((scan) => scan.riskScore >= 70).toList();
  }
}
