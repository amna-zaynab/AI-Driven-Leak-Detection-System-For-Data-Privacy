import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

import 'permissions_page.dart';
import 'phishingurldetection.dart';
import 'report_page.dart';
import 'login_page.dart';
import 'email_breach_page.dart';
import 'services/app_history_service.dart';
import 'services/network_diagnostic.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _scannedAppsCount = 0;
  double _privacyScore = 100.0;
  int _highRiskApps = 0;
  int _malwareApps = 0;
  String? _email;
  bool _isLoadingPrivacyScore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserEmail();
    _loadScannedAppsCount();
    _fetchPrivacyScore();

    // Run network diagnostic in background
    debugPrint('📱 Dashboard initialized, running network diagnostic...');
    NetworkDiagnostic.testConnectivity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when returning to dashboard
      _loadScannedAppsCount();
      _fetchPrivacyScore();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _email = prefs.getString('user_email'));
  }

  Future<void> _loadScannedAppsCount() async {
    try {
      final count = await AppHistoryService.getScannedAppsCount();
      if (mounted) {
        setState(() => _scannedAppsCount = count);
      }
      debugPrint('📊 Loaded scanned apps count: $count');
    } catch (e) {
      debugPrint('❌ Error loading scanned apps count: $e');
    }
  }

  Future<void> _fetchPrivacyScore() async {
    if (mounted) {
      setState(() => _isLoadingPrivacyScore = true);
    }
    try {
      // Try with local server first, then fallback to network
      SharedPreferences sh = await SharedPreferences.getInstance();
      final urls = [
        '${sh.getString("ip")}/api/get_privacy_score/',
        '${sh.getString("ip")}/api/get_privacy_score/',
      ];

      for (final urlString in urls) {
        try {
          final url = Uri.parse(urlString);
          debugPrint('🔄 Fetching privacy score from: $url');

          final response = await http
              .get(url)
              .timeout(const Duration(seconds: 8));
          debugPrint(
            '📊 Privacy score response status: ${response.statusCode}',
          );
          debugPrint('📊 Privacy score response body: ${response.body}');

          if (response.statusCode == 200 && mounted) {
            final data = jsonDecode(response.body);
            setState(() {
              _privacyScore = (data['privacy_score'] ?? 100.0).toDouble();
              _scannedAppsCount = data['total_apps_scanned'] ?? 0;
              _highRiskApps = data['high_risk_apps'] ?? 0;
              _malwareApps = data['malware_apps'] ?? 0;
              _isLoadingPrivacyScore = false;
            });
            debugPrint('✅ Privacy score updated: $_privacyScore%');
            debugPrint(
              '📊 Apps scanned: $_scannedAppsCount | High risk: $_highRiskApps | Malware: $_malwareApps',
            );
            return; // Success, exit the function
          }
        } catch (e) {
          debugPrint('⚠️ Failed to connect to $urlString: $e');
          continue; // Try next URL
        }
      }

      // If all URLs failed
      if (mounted) {
        setState(() => _isLoadingPrivacyScore = false);
        debugPrint('❌ Could not connect to any server');
      }
    } catch (e) {
      debugPrint('❌ Error in privacy score fetch: $e');
      if (mounted) {
        setState(() => _isLoadingPrivacyScore = false);
      }
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _onScanPressed() async {
    final apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      // Keep flags aligned with PermissionsPage to match the count
      // includeSystemApps: false,
      // onlyAppsWithLaunchIntent: false,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PermissionsPage()),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Signed in",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _email ?? "Not signed in",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const PermissionsPage();
      case 2:
        return const EmailBreachPage();
      case 3:
        return const LeakDetectionPage();
      case 4:
        return const ReportPage();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: title on left, user icon on right (same line)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Privacy Dashboard",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _showAccountSheet,
                  child: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              "Monitor and protect your digital privacy",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 30),

            // Scanner button
            Center(
              child: GestureDetector(
                onTap: _onScanPressed,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.lightBlueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _scannedAppsCount == 0
                    ? "Tap to scan app permissions"
                    : "Last scan: $_scannedAppsCount apps scanned",
                style: const TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 30),

            // Refresh button
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                onPressed: () {
                  _fetchPrivacyScore();
                },
                tooltip: 'Refresh metrics',
              ),
            ),

            // Stats cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoCard(
                  "$_scannedAppsCount",
                  "Apps Scanned",
                  Icons.apps,
                  Colors.green,
                ),
                _isLoadingPrivacyScore
                    ? _buildLoadingInfoCard("Privacy Score", Icons.shield)
                    : _buildInfoCard(
                        "${_privacyScore.toStringAsFixed(1)}%",
                        "Privacy Score",
                        Icons.shield,
                        _getPrivacyScoreColor(),
                      ),
              ],
            ),

            const SizedBox(height: 20),

            // Risk indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoCard(
                  "$_highRiskApps",
                  "High Risk",
                  Icons.warning,
                  Colors.orange,
                ),
                _buildInfoCard(
                  "$_malwareApps",
                  "Malware",
                  Icons.dangerous,
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Risk Distribution Pie Chart
            const Text(
              "Risk Distribution",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            _buildRiskDistributionChart(),

            const SizedBox(height: 30),

            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            _buildQuickAction(
              Icons.security,
              "App Permissions",
              "Review and manage app permissions",
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PermissionsPage(),
                ),
              ),
            ),
            const SizedBox(height: 10),

            _buildQuickAction(
              Icons.warning,
              "Privacy Leaks",
              "Detect potential privacy breaches",
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeakDetectionPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLoadingInfoCard(String label, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 30),
          const SizedBox(height: 10),
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getPrivacyScoreColor() {
    if (_privacyScore >= 80) return Colors.green;
    if (_privacyScore >= 60) return Colors.amber;
    if (_privacyScore >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0A0F1C),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: "Permissions",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mark_email_read),
            label: "Breaches",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link_off),
            label: "Phishing",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: "Reports",
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistributionChart() {
    int safeApps = _scannedAppsCount - _highRiskApps - _malwareApps;
    safeApps = safeApps < 0 ? 0 : safeApps;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2B3C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: [
                  if (safeApps > 0)
                    PieChartSectionData(
                      value: safeApps.toDouble(),
                      title: '$safeApps',
                      radius: 60,
                      color: Colors.green,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (_highRiskApps > 0)
                    PieChartSectionData(
                      value: _highRiskApps.toDouble(),
                      title: '$_highRiskApps',
                      radius: 60,
                      color: Colors.orange,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (_malwareApps > 0)
                    PieChartSectionData(
                      value: _malwareApps.toDouble(),
                      title: '$_malwareApps',
                      radius: 60,
                      color: Colors.red,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(Colors.green, "Safe ($safeApps)"),
              _buildLegendItem(Colors.orange, "High Risk ($_highRiskApps)"),
              _buildLegendItem(Colors.red, "Malware ($_malwareApps)"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
