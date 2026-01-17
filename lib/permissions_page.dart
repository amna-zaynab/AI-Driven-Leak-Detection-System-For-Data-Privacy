import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'analysis_results_page.dart';
import 'services/app_history_service.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  static const platform = MethodChannel('com.example.privacy_app/permissions');

  List<AppInfo> _installedApps = [];
  final Map<String, List<String>> _requestedPermissions = {};
  final Map<String, List<String>> _grantedPermissions = {};
  final Map<String, Set<String>> _selectedRequested = {};
  final Map<String, Set<String>> _selectedGranted = {};

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
    );

    List<AppInfo> appInfos = [];
    for (var app in apps) {
      if (app is ApplicationWithIcon) {
        final iconBase64 = base64Encode(app.icon);

        appInfos.add(
          AppInfo(
            name: app.appName,
            packageName: app.packageName,
            iconBase64: iconBase64,
          ),
        );

        // Get permissions for each app
        try {
          final result = await platform.invokeMethod('getPermissions', {
            "packageName": app.packageName,
          });

          List<String> requested = List<String>.from(
            result["requested"] ?? [],
          ).toSet().toList();
          List<String> granted = List<String>.from(
            result["granted"] ?? [],
          ).toSet().toList();

          _requestedPermissions[app.packageName] = requested;
          _grantedPermissions[app.packageName] = granted;
        } catch (e) {
          debugPrint("Error fetching permissions: $e");
        }
      }
    }

    setState(() {
      _installedApps = appInfos;
    });
  }

  String _friendlyName(String permission) {
    if (permission.contains("CONTACTS")) return "Contacts";
    if (permission.contains("LOCATION")) return "Location";
    if (permission.contains("CAMERA")) return "Camera";
    if (permission.contains("MICROPHONE")) return "Microphone";
    if (permission.contains("STORAGE")) return "Storage";
    if (permission.contains("SMS")) return "SMS";
    if (permission.contains("CALL")) return "Phone Calls";
    if (permission.contains("CALENDAR")) return "Calendar";
    if (permission.contains("SENSORS")) return "Sensors";
    if (permission.contains("BLUETOOTH")) return "Bluetooth";
    if (permission.contains("INTERNET")) return "Internet";
    return permission.split('.').last; // fallback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("App Permissions")),
      body: _installedApps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _installedApps.length,
              itemBuilder: (context, index) {
                final app = _installedApps[index];
                final requested = _requestedPermissions[app.packageName] ?? [];
                final granted = _grantedPermissions[app.packageName] ?? [];

                // Decode icon once and cache
                Uint8List? appIcon;
                if (app.iconBase64.isNotEmpty) {
                  appIcon = Base64Decoder().convert(app.iconBase64);
                }

                return Card(
                  margin: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: appIcon != null
                        ? Image.memory(appIcon, width: 40, height: 40)
                        : const Icon(Icons.apps),
                    title: Text(app.name),
                    subtitle: Text(
                      app.packageName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => _sendPermissionsForApp(app),
                    trailing: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _sendPermissionsForApp(app),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _sendSelectedPermissions() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/submit_permissions/');
    final entries = <Map<String, dynamic>>[];

    for (var app in _installedApps) {
      final pkg = app.packageName;
      final reqSel = _selectedRequested[pkg]?.toList() ?? [];
      final grdSel = _selectedGranted[pkg]?.toList() ?? [];
      if (reqSel.isEmpty && grdSel.isEmpty) continue;
      entries.add({'packageName': pkg, 'requested': reqSel, 'granted': grdSel});
    }

    if (entries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No permissions selected')));
      return;
    }

    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'entries': entries}),
      );
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final responseData = jsonDecode(resp.body);
        final List<dynamic> resultsList = responseData['results'] ?? [];
        final results = resultsList
            .map((r) => AnalysisResult.fromJson(r as Map<String, dynamic>))
            .toList();

        // Save each result to app history
        for (var result in results) {
          final appName = _getAppNameFromPackage(result.packageName);
          await AppHistoryService.addScan(
            AppScan(
              packageName: result.packageName,
              appName: appName,
              scanDate: DateTime.now(),
              riskScore: result.riskScore,
              riskLevel: result.riskLevel,
              prediction: result.prediction,
            ),
          );
        }

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AnalysisResultsPage(results: results),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  Future<void> _sendPermissionsForApp(AppInfo app) async {
    final pkg = app.packageName;
    final requested = _requestedPermissions[pkg] ?? [];
    final granted = _grantedPermissions[pkg] ?? [];
    SharedPreferences sh = await SharedPreferences.getInstance();

    final url = Uri.parse('${sh.getString("ip")}/api/submit_permissions/');
    final entries = [
      {'packageName': pkg, 'requested': requested, 'granted': granted},
    ];

    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'entries': entries}),
      );
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final responseData = jsonDecode(resp.body);
        final List<dynamic> resultsList = responseData['results'] ?? [];
        final results = resultsList
            .map((r) => AnalysisResult.fromJson(r as Map<String, dynamic>))
            .toList();

        // Save each result to app history
        for (var result in results) {
          await AppHistoryService.addScan(
            AppScan(
              packageName: result.packageName,
              appName: app.name,
              scanDate: DateTime.now(),
              riskScore: result.riskScore,
              riskLevel: result.riskLevel,
              prediction: result.prediction,
            ),
          );
        }

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AnalysisResultsPage(results: results),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  String _getAppNameFromPackage(String packageName) {
    final app = _installedApps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () =>
          AppInfo(name: packageName, packageName: packageName, iconBase64: ''),
    );
    return app.name;
  }
}

class AppInfo {
  final String name;
  final String packageName;
  final String iconBase64;

  AppInfo({
    required this.name,
    required this.packageName,
    required this.iconBase64,
  });
}
