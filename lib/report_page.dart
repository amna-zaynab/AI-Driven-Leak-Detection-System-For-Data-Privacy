import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'services/notification_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _loading = true;
  String? _error;
  bool _generatingPDF = false;

  // Report data
  int _totalAppsScanned = 0;
  int _highRiskApps = 0;
  int _malwareApps = 0;
  int _safeApps = 0;
  int _breachesDetected = 0;
  int _phishingUrlsDetected = 0;
  String _userEmail = '';
  String _baseUrl = '';
  List<Map<String, dynamic>> _breachHistory = [];
  List<Map<String, dynamic>> _phishingHistory = [];
  List<Map<String, dynamic>> _scannedApps = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadReportData();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService().initialize(
      onTap: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          NotificationService().openFile(response.payload!);
        }
      },
    );
  }

  Future<void> _loadReportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? '';
      final baseUrl = prefs.getString('ip') ?? '';

      setState(() {
        _userEmail = email;
        _baseUrl = baseUrl;
      });

      if (email.isEmpty || baseUrl.isEmpty) {
        setState(() {
          _error = 'User email or base URL not configured';
          _loading = false;
        });
        return;
      }

      // Load all data
      await _loadPrivacyStats(baseUrl);
      await _loadBreachHistory(baseUrl, email);
      await _loadPhishingHistory(baseUrl, email);
      await _loadScannedApps(baseUrl);

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading report: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadPrivacyStats(String baseUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_privacy_score/'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _totalAppsScanned = data['total_apps_scanned'] ?? 0;
            _highRiskApps = data['high_risk_apps'] ?? 0;
            _malwareApps = data['malware_apps'] ?? 0;
            _safeApps = _totalAppsScanned - _highRiskApps - _malwareApps;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading privacy stats: $e');
    }
  }

  Future<void> _loadBreachHistory(String baseUrl, String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_breaches/$email/'),
      );
      debugPrint('Breach response status: ${response.statusCode}');
      debugPrint('Breach response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final breaches = List<Map<String, dynamic>>.from(
          data['breaches'] ?? [],
        );
        if (mounted) {
          setState(() {
            _breachHistory = breaches;
            _breachesDetected = breaches.length;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading breach history: $e');
    }
  }

  Future<void> _loadPhishingHistory(String baseUrl, String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_phishing_history/?user=$email'),
      );
      debugPrint('Phishing response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final phishing = List<Map<String, dynamic>>.from(data['records'] ?? []);
        if (mounted) {
          setState(() {
            _phishingHistory = phishing;
            _phishingUrlsDetected = phishing.length;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading phishing history: $e');
    }
  }

  Future<void> _loadScannedApps(String baseUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_scanned_apps/'),
      );
      debugPrint('Scanned apps response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final apps = List<Map<String, dynamic>>.from(data['apps'] ?? []);
        if (mounted) {
          setState(() {
            _scannedApps = apps;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading scanned apps: $e');
    }
  }

  Future<void> _generateAndSharePDF() async {
    setState(() => _generatingPDF = true);

    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      // Add cover page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Privacy & Security Report',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Comprehensive Device Security Analysis',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Divider(),
                pw.SizedBox(height: 40),
                pw.Text(
                  'User: $_userEmail',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Generated: ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Device Security Score',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '${_calculateSecurityScore()}%',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: _calculateSecurityScore() >= 80
                        ? PdfColors.green
                        : _calculateSecurityScore() >= 60
                        ? PdfColors.orange
                        : PdfColors.red,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Executive Summary page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Executive Summary',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  'Report Highlights:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildDetailedSummaryItem(
                  'Total Apps Scanned',
                  _totalAppsScanned.toString(),
                ),
                _buildDetailedSummaryItem(
                  'Safe Applications',
                  _safeApps.toString(),
                ),
                _buildDetailedSummaryItem(
                  'High-Risk Applications',
                  _highRiskApps.toString(),
                ),
                _buildDetailedSummaryItem(
                  'Malware Detected',
                  _malwareApps.toString(),
                ),
                _buildDetailedSummaryItem(
                  'Data Breaches Found',
                  _breachesDetected.toString(),
                ),
                _buildDetailedSummaryItem(
                  'Phishing URLs Detected',
                  _phishingUrlsDetected.toString(),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Security Status:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  _getSecurityStatus(),
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Recommendations:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ..._getRecommendations().map((rec) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                      '• $rec',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      );

      // Detailed Statistics page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Detailed Statistics',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'App Security Distribution',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPDFStat('Total\nApps', _totalAppsScanned.toString()),
                    _buildPDFStat('Safe\nApps', _safeApps.toString()),
                    _buildPDFStat('High\nRisk', _highRiskApps.toString()),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPDFStat('Malware\nDetected', _malwareApps.toString()),
                    _buildPDFStat(
                      'Data\nBreaches',
                      _breachesDetected.toString(),
                    ),
                    _buildPDFStat(
                      'Phishing\nURLs',
                      _phishingUrlsDetected.toString(),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Risk Assessment Bar Chart:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildPDFBarChart(),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Detailed Risk Breakdown:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildRiskBar(
                  'Safe Apps',
                  _safeApps,
                  _totalAppsScanned,
                  PdfColors.green,
                ),
                _buildRiskBar(
                  'High Risk',
                  _highRiskApps,
                  _totalAppsScanned,
                  PdfColors.orange,
                ),
                _buildRiskBar(
                  'Malware',
                  _malwareApps,
                  _totalAppsScanned,
                  PdfColors.red,
                ),
              ],
            );
          },
        ),
      );

      // Scanned Apps page
      if (_scannedApps.isNotEmpty) {
        // Split into pages if more than 15 apps
        for (int i = 0; i < _scannedApps.length; i += 15) {
          final endIndex = (i + 15 < _scannedApps.length)
              ? i + 15
              : _scannedApps.length;
          final pageApps = _scannedApps.sublist(i, endIndex);

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Scanned Applications',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Page ${(i ~/ 15) + 1} of ${(_scannedApps.length + 14) ~/ 15}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Column(
                      children: pageApps.map((app) {
                        return _buildAppListItem(app);
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          );
        }
      }

      // Breaches page
      if (_breachHistory.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              final groupedBreaches = <String, List<Map<String, dynamic>>>{};
              for (final breach in _breachHistory) {
                final date =
                    (breach['breach_date'] as String?)?.split('T').first ??
                        'Unknown';
                groupedBreaches.putIfAbsent(date, () => []).add(breach);
              }

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Data Breaches Detected',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Total Breaches Found: ${_breachHistory.length}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.red,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.ListView.builder(
                    itemCount: groupedBreaches.length,
                    itemBuilder: (context, index) {
                      final entry = groupedBreaches.entries.toList()[index];
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Date: ${entry.key}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          ...entry.value.map((breach) {
                            return pw.Padding(
                              padding: const pw.EdgeInsets.only(
                                left: 10,
                                top: 5,
                                bottom: 5,
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Breach: ${breach['breach_name'] ?? 'Unknown'}',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                  pw.Text(
                                    'Description: ${breach['description'] ?? 'No description'}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                  if (breach['data_classes'] != null)
                                    pw.Text(
                                      'Data Affected: ${breach['data_classes']}',
                                      style: const pw.TextStyle(fontSize: 9),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          pw.SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      }

      // Phishing page
      if (_phishingHistory.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              final groupedPhishing = <String, List<Map<String, dynamic>>>{};
              for (final record in _phishingHistory) {
                final date =
                    (record['detected_at'] as String?)?.split('T').first ??
                        'Unknown';
                groupedPhishing.putIfAbsent(date, () => []).add(record);
              }

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Phishing & Malicious URLs',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Total Threats Found: ${_phishingHistory.length}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.red,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.ListView.builder(
                    itemCount: groupedPhishing.length,
                    itemBuilder: (context, index) {
                      final entry = groupedPhishing.entries.toList()[index];
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Date: ${entry.key}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          ...entry.value.map((record) {
                            final riskLevel = record['risk_level']
                                .toString()
                                .toUpperCase();
                            final confidence =
                            (record['confidence_score'] * 100)
                                .toStringAsFixed(0);
                            return pw.Padding(
                              padding: const pw.EdgeInsets.only(
                                left: 10,
                                top: 5,
                                bottom: 5,
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'URL: ${record['url']}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                  pw.Text(
                                    'Risk Level: $riskLevel | Confidence: $confidence%',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                  if (record['description'] != null)
                                    pw.Text(
                                      'Details: ${record['description']}',
                                      style: const pw.TextStyle(fontSize: 8),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          pw.SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      }

      // Recommendations page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Security Recommendations',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                ..._generateRecommendationsList().asMap().entries.map((entry) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${entry.key + 1}. ${entry.value['title']}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          entry.value['description'] ??
                              'Security recommendation',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      );

      // Footer page with disclaimer
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Report Information',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Generated on: ${dateFormat.format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'User Email: $_userEmail',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Disclaimer:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'This report is generated based on the security analysis of your device. While we strive to provide accurate information, this report should not be considered as professional security advice. For critical security concerns, please consult with professional cybersecurity experts.',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'For more information and updates, regularly check your Privacy App for the latest security reports.',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.Divider(),
                pw.Text(
                  'Privacy & Security Report - Confidential',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      final dir = await getDownloadsDirectory();
      debugPrint('Downloads directory: ${dir?.path}');

      if (dir != null) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'Privacy_Report_$timestamp.pdf';
          final filePath = '${dir.path}/$fileName';
          final file = File(filePath);

          debugPrint('Saving PDF to: $filePath');
          final pdfBytes = await pdf.save();
          debugPrint('PDF bytes generated: ${pdfBytes.length}');

          await file.writeAsBytes(pdfBytes);
          debugPrint('PDF file written successfully');

          // Verify file exists
          final exists = await file.exists();
          debugPrint('File exists after write: $exists');

          if (mounted) {
            // Show notification
            try {
              await NotificationService().showDownloadNotification(
                fileName: fileName,
                filePath: filePath,
              );
              debugPrint('Notification shown');
            } catch (notifError) {
              debugPrint('Notification error (PDF still saved): $notifError');
              // Show snackbar instead if notification fails
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('PDF saved: $fileName')));
            }
          }
        } catch (fileError) {
          debugPrint('File write error: $fileError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving PDF: $fileError')),
            );
          }
        }
      } else {
        debugPrint('Downloads directory is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not access Downloads directory'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('PDF generation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _generatingPDF = false);
      }
    }
  }

  pw.Widget _buildPDFStat(String title, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildDetailedSummaryItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFBarChart() {
    // Create a simple bar chart using containers
    final maxHeight = _totalAppsScanned > 0 ? _totalAppsScanned : 100;
    final safeHeight =
    (_totalAppsScanned > 0 ? (_safeApps / maxHeight) * 100 : 0.0)
        .toDouble();
    final highRiskHeight =
    (_totalAppsScanned > 0 ? (_highRiskApps / maxHeight) * 100 : 0.0)
        .toDouble();
    final malwareHeight =
    (_totalAppsScanned > 0 ? (_malwareApps / maxHeight) * 100 : 0.0)
        .toDouble();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildBarColumn(
              'Safe\nApps',
              _safeApps,
              safeHeight,
              PdfColors.green,
            ),
            _buildBarColumn(
              'High\nRisk',
              _highRiskApps,
              highRiskHeight,
              PdfColors.orange,
            ),
            _buildBarColumn(
              'Malware',
              _malwareApps,
              malwareHeight,
              PdfColors.red,
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Safe Apps', PdfColors.green),
            _buildLegendItem('High Risk', PdfColors.orange),
            _buildLegendItem('Malware', PdfColors.red),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBarColumn(
      String label,
      int count,
      double heightPercent,
      PdfColor color,
      ) {
    return pw.Column(
      children: [
        pw.Container(
          width: 30,
          height: heightPercent * 1.2,
          decoration: pw.BoxDecoration(
            color: color,
            border: pw.Border.all(),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          count.toString(),
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildLegendItem(String label, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(color: color, border: pw.Border.all()),
        ),
        pw.SizedBox(width: 5),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  pw.Widget _buildAppListItem(Map<String, dynamic> app) {
    final packageName = app['package_name'] ?? 'Unknown';
    final riskScore = app['risk_score'] ?? 0;
    final prediction = app['prediction'] ?? 'unknown';
    final riskLevel = app['risk_level'] ?? 'unknown';
    final permissions = app['permission_count'] ?? 0;

    PdfColor statusColor = PdfColors.green;
    if (prediction == 'malware') {
      statusColor = PdfColors.red;
    } else if (riskLevel == 'high') {
      statusColor = PdfColors.orange;
    } else if (riskLevel == 'medium') {
      statusColor = PdfColors.amber;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: statusColor),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              packageName,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Risk Score: $riskScore/100',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Status: $riskLevel',
                  style: pw.TextStyle(fontSize: 9, color: statusColor),
                ),
                pw.Text(
                  'Permissions: $permissions',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildRiskBar(String label, int count, int total, PdfColor color) {
    final percentage = total > 0 ? (count / total) : 0.0;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label: $count/$total (${(percentage * 100).toStringAsFixed(1)}%)',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            height: 20,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 200 * percentage,
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: color,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateSecurityScore() {
    if (_totalAppsScanned == 0) return 100;

    final safePercentage = (_safeApps / _totalAppsScanned) * 100;
    final riskReduction = (_highRiskApps + _malwareApps) * 5;
    final breachPenalty = _breachesDetected * 10;
    final phishingPenalty = _phishingUrlsDetected * 5;

    int score = (safePercentage + 50).toInt();
    score -= riskReduction.toInt();
    score -= breachPenalty;
    score -= phishingPenalty;

    return score.clamp(0, 100);
  }

  String _getSecurityStatus() {
    final score = _calculateSecurityScore();
    if (score >= 80) {
      return 'Your device security is GOOD. Continue monitoring for threats.';
    } else if (score >= 60) {
      return 'Your device security is MODERATE. Consider taking recommended actions.';
    } else {
      return 'Your device security is POOR. Take immediate action on high-risk applications and threats.';
    }
  }

  List<String> _getRecommendations() {
    final recommendations = <String>[];

    if (_highRiskApps > 0) {
      recommendations.add(
        'Uninstall or update ${_highRiskApps} high-risk application(s)',
      );
    }
    if (_malwareApps > 0) {
      recommendations.add(
        'Immediately remove $_malwareApps malicious application(s)',
      );
    }
    if (_breachesDetected > 0) {
      recommendations.add(
        'Change passwords for $_breachesDetected affected account(s)',
      );
    }
    if (_phishingUrlsDetected > 0) {
      recommendations.add(
        'Avoid visiting $_phishingUrlsDetected detected phishing/malicious URL(s)',
      );
    }

    // App-specific recommendations
    if (_scannedApps.isNotEmpty) {
      for (final app in _scannedApps) {
        final prediction = app['prediction'] ?? 'unknown';
        if (prediction == 'malware') {
          final packageName = app['package_name'] ?? 'Unknown App';
          recommendations.add(
            'URGENT: Uninstall "$packageName" - confirmed malware detected',
          );
        }
      }

      final highRiskAppsInList = _scannedApps.where((app) {
        final riskScore = app['risk_score'] ?? 0;
        return riskScore >= 70 && app['prediction'] != 'malware';
      }).toList();

      if (highRiskAppsInList.isNotEmpty) {
        for (final app in highRiskAppsInList.take(3)) {
          final packageName = app['package_name'] ?? 'Unknown';
          final permissions = app['permission_count'] ?? 0;
          recommendations.add(
            'Review "$packageName" - requires $permissions permissions with high-risk score',
          );
        }
      }
    }

    if (_totalAppsScanned > 0 && (_highRiskApps + _malwareApps) == 0) {
      recommendations.add(
        'Keep your device updated and perform regular security scans',
      );
    }

    return recommendations;
  }

  List<Map<String, String>> _generateRecommendationsList() {
    return [
      {
        'title': 'Review Installed Applications',
        'description':
        'Regularly review and audit installed applications. Remove apps you no longer use and are unsure about.',
      },
      {
        'title': 'Update Software Regularly',
        'description':
        'Keep your device OS and applications up to date. Security patches are essential for protection.',
      },
      {
        'title': 'Enable Two-Factor Authentication',
        'description':
        'Enable 2FA on critical accounts to add an extra layer of security.',
      },
      {
        'title': 'Monitor Data Breaches',
        'description':
        'If your email appears in data breaches, consider changing passwords on affected services.',
      },
      {
        'title': 'Avoid Phishing Links',
        'description':
        'Be cautious of suspicious links and emails. Never click links from unknown sources.',
      },
      {
        'title': 'Use Strong Passwords',
        'description':
        'Use unique, strong passwords for each account. Consider using a password manager.',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F1C),
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F1C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0F1C),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Privacy Report'),
        ),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Privacy Report',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: _generatingPDF ? null : _generateAndSharePDF,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4444), Color(0xFFFF6666)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: _generatingPDF
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'PDF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 28),
              _buildAppRiskChart(),
              const SizedBox(height: 28),
              _buildPhishingRiskChart(),
              const SizedBox(height: 28),
              _buildBreachesSection(),
              const SizedBox(height: 28),
              _buildPhishingSection(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Summary',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildAnimatedStatCard(
              'Apps Scanned',
              _totalAppsScanned.toString(),
              Colors.blue,
              Icons.apps,
            ),
            _buildAnimatedStatCard(
              'High Risk',
              _highRiskApps.toString(),
              Colors.orange,
              Icons.warning,
            ),
            _buildAnimatedStatCard(
              'Malware',
              _malwareApps.toString(),
              Colors.red,
              Icons.coronavirus,
            ),
            _buildAnimatedStatCard(
              'Safe Apps',
              _safeApps.toString(),
              Colors.green,
              Icons.shield_outlined,
            ),
            _buildAnimatedStatCard(
              'Breaches',
              _breachesDetected.toString(),
              Colors.purple,
              Icons.security,
            ),
            _buildAnimatedStatCard(
              'Phishing URLs',
              _phishingUrlsDetected.toString(),
              Colors.red[900]!,
              Icons.link_off,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedStatCard(
      String title,
      String value,
      Color color,
      IconData icon,
      ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF121828),
            const Color(0xFF1A2332).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppRiskChart() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF121828),
            const Color(0xFF1A2332).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Risk Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (_totalAppsScanned == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No apps scanned yet',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: [
                    if (_safeApps > 0)
                      PieChartSectionData(
                        value: _safeApps.toDouble(),
                        title: 'Safe\n$_safeApps',
                        color: Colors.green,
                        radius: 65,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (_highRiskApps > 0)
                      PieChartSectionData(
                        value: _highRiskApps.toDouble(),
                        title: 'High\n$_highRiskApps',
                        color: Colors.orange,
                        radius: 65,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (_malwareApps > 0)
                      PieChartSectionData(
                        value: _malwareApps.toDouble(),
                        title: 'Malware\n$_malwareApps',
                        color: Colors.red,
                        radius: 65,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhishingRiskChart() {
    int safe = 0, suspicious = 0, phishing = 0, malware = 0;

    for (final record in _phishingHistory) {
      switch (record['risk_level']) {
        case 'safe':
          safe++;
          break;
        case 'suspicious':
          suspicious++;
          break;
        case 'phishing':
          phishing++;
          break;
        case 'malware':
          malware++;
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF121828),
            const Color(0xFF1A2332).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phishing URL Risk Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (_phishingUrlsDetected == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No URLs checked yet',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: [
                    if (safe > 0)
                      PieChartSectionData(
                        value: safe.toDouble(),
                        title: 'Safe\n$safe',
                        color: Colors.green,
                        radius: 65,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (suspicious > 0)
                      PieChartSectionData(
                        value: suspicious.toDouble(),
                        title: 'Suspicious\n$suspicious',
                        color: Colors.orange,
                        radius: 65,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (phishing > 0)
                      PieChartSectionData(
                        value: phishing.toDouble(),
                        title: 'Phishing\n$phishing',
                        color: Colors.red,
                        radius: 65,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (malware > 0)
                      PieChartSectionData(
                        value: malware.toDouble(),
                        title: 'Malware\n$malware',
                        color: Colors.red[900]!,
                        radius: 65,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreachesSection() {
    if (_breachHistory.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF121828),
              const Color(0xFF1A2332).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.withOpacity(0.2), width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            '✓ No breaches detected for your account',
            style: TextStyle(
              color: Colors.green,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Group breaches by date
    final groupedBreaches = <String, List<Map<String, dynamic>>>{};
    for (final breach in _breachHistory) {
      final date =
          (breach['breach_date'] as String?)?.split('T').first ?? 'Unknown';
      groupedBreaches.putIfAbsent(date, () => []).add(breach);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF121828),
            const Color(0xFF1A2332).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Data Breaches Detected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_breachHistory.length} found',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...groupedBreaches.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...entry.value.map((breach) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    breach['breach_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    breach['description'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPhishingSection() {
    if (_phishingHistory.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF121828),
              const Color(0xFF1A2332).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            '✓ No suspicious URLs detected',
            style: TextStyle(
              color: Colors.green,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Group phishing by date
    final groupedPhishing = <String, List<Map<String, dynamic>>>{};
    for (final record in _phishingHistory) {
      final date =
          (record['detected_at'] as String?)?.split('T').first ?? 'Unknown';
      groupedPhishing.putIfAbsent(date, () => []).add(record);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF121828),
            const Color(0xFF1A2332).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phishing URLs Checked',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_phishingHistory.length} checked',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...groupedPhishing.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...entry.value.map((record) {
                    final riskColor = _getRiskColor(record['risk_level']);
                    final riskLevel = record['risk_level']
                        .toString()
                        .toUpperCase();
                    final confidence = (record['confidence_score'] * 100)
                        .toStringAsFixed(0);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: riskColor.withOpacity(0.2)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(
                                color: riskColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record['url'] ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: riskColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '$riskLevel',
                                          style: TextStyle(
                                            color: riskColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$confidence% confidence',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
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
}
