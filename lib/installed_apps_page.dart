// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:url_launcher/url_launcher_string.dart';
//
// class InstalledAppsPage extends StatefulWidget {
//   const InstalledAppsPage({super.key});
//
//   @override
//   State<InstalledAppsPage> createState() => _InstalledAppsPageState();
// }
//
// class InstalledApp {
//   final String appName;
//   final String packageName;
//   final bool systemApp;
//   final Uint8List? icon;
//
//   InstalledApp({
//     required this.appName,
//     required this.packageName,
//     required this.systemApp,
//     this.icon,
//   });
//
//   factory InstalledApp.fromMap(Map<dynamic, dynamic> m) {
//     final iconBase64 = m['icon'] as String?;
//     Uint8List? iconBytes;
//     if (iconBase64 != null) {
//       try {
//         iconBytes = base64Decode(iconBase64);
//       } catch (_) {
//         iconBytes = null;
//       }
//     }
//
//     return InstalledApp(
//       appName: m['appName'] as String? ?? '',
//       packageName: m['packageName'] as String? ?? '',
//       systemApp: m['systemApp'] as bool? ?? false,
//       icon: iconBytes,
//     );
//   }
// }
//
// class _InstalledAppsPageState extends State<InstalledAppsPage> {
//   final MethodChannel _channel = const MethodChannel(
//     'com.example.privacy_app/permissions',
//   );
//   List<InstalledApp> _apps = [];
//   bool _loading = true;
//   int? _rawCount;
//   List<String>? _rawNames;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadInstalledApps();
//   }
//
//   Future<void> _loadInstalledApps() async {
//     try {
//       final result = await _channel.invokeMethod('getInstalledApps');
//
//       List<dynamic> list = [];
//       int? rawCount;
//       List<String>? rawNames;
//
//       if (result is Map) {
//         // diagnostic payload from native side
//         list = (result['apps'] as List<dynamic>?) ?? [];
//         final rc = result['rawCount'];
//         if (rc is int)
//           rawCount = rc;
//         else if (rc is num)
//           rawCount = rc.toInt();
//         final rn = result['rawNames'] as List<dynamic>?;
//         if (rn != null) rawNames = rn.map((e) => e?.toString() ?? '').toList();
//       } else {
//         list = (result as List<dynamic>?) ?? [];
//       }
//
//       final apps =
//           list
//               .map(
//                 (e) =>
//                     InstalledApp.fromMap(Map<dynamic, dynamic>.from(e as Map)),
//               )
//               .toList();
//
//       // sort: user apps first
//       apps.sort((a, b) => (a.systemApp ? 1 : 0).compareTo(b.systemApp ? 1 : 0));
//
//       setState(() {
//         _apps = apps;
//         _rawCount = rawCount;
//         _rawNames = rawNames;
//         _loading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _apps = [];
//         _loading = false;
//       });
//     }
//   }
//
//   Widget _buildTile(InstalledApp app) {
//     final subtitle = app.systemApp ? 'System app' : 'User app';
//
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       child: ListTile(
//         leading:
//             app.icon != null
//                 ? Image.memory(app.icon!, width: 40, height: 40)
//                 : const Icon(Icons.apps),
//         title: Text(app.appName),
//         subtitle: Text('${app.packageName} • $subtitle'),
//         trailing: const Icon(Icons.chevron_right),
//         onTap: () async {
//           final pkg = app.packageName;
//           final intentUri = 'intent://#Intent;package=$pkg;end';
//           final playStore =
//               'https://play.google.com/store/apps/details?id=$pkg';
//           try {
//             final launched = await launchUrlString(
//               intentUri,
//               mode: LaunchMode.externalApplication,
//             );
//             if (!launched)
//               await launchUrlString(
//                 playStore,
//                 mode: LaunchMode.externalApplication,
//               );
//           } catch (_) {
//             await launchUrlString(
//               playStore,
//               mode: LaunchMode.externalApplication,
//             );
//           }
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Installed Apps')),
//       body:
//           _loading
//               ? const Center(child: CircularProgressIndicator())
//               import 'dart:typed_data';
//               import 'package:flutter/material.dart';
//               import 'package:device_apps/device_apps.dart';
//               import 'package:url_launcher/url_launcher_string.dart';
//
//               class InstalledAppsPage extends StatefulWidget {
//                 const InstalledAppsPage({super.key});
//
//                 @override
//                 State<InstalledAppsPage> createState() => _InstalledAppsPageState();
//               }
//
//               class InstalledApp {
//                 final String appName;
//                 final String packageName;
//                 final bool systemApp;
//                 final Uint8List? icon;
//
//                 InstalledApp({
//                   required this.appName,
//                   required this.packageName,
//                   required this.systemApp,
//                   this.icon,
//                 });
//               }
//
//               class _InstalledAppsPageState extends State<InstalledAppsPage> {
//                 List<InstalledApp> _apps = [];
//                 bool _loading = true;
//
//                 @override
//                 void initState() {
//                   super.initState();
//                   _loadInstalledApps();
//                 }
//
//                 Future<void> _loadInstalledApps() async {
//                   setState(() => _loading = true);
//                   try {
//                     final appsRaw = await DeviceApps.getInstalledApplications(
//                       includeAppIcons: true,
//                       includeSystemApps: true,
//                       onlyAppsWithLaunchIntent: false,
//                     );
//
//                     final apps = appsRaw.map((a) {
//                       if (a is ApplicationWithIcon) {
//                         return InstalledApp(
//                           appName: a.appName,
//                           packageName: a.packageName,
//                           systemApp: a.systemApp ?? false,
//                           icon: a.icon,
//                         );
//                       } else if (a is Application) {
//                         return InstalledApp(
//                           appName: a.appName,
//                           packageName: a.packageName,
//                           systemApp: a.systemApp ?? false,
//                           icon: null,
//                         );
//                       } else {
//                         return InstalledApp(appName: a.toString(), packageName: '', systemApp: false);
//                       }
//                     }).toList();
//
//                     apps.sort((a, b) => (a.systemApp ? 1 : 0).compareTo(b.systemApp ? 1 : 0));
//
//                     setState(() {
//                       _apps = apps;
//                       _loading = false;
//                     });
//                   } catch (e) {
//                     setState(() {
//                       _apps = [];
//                       _loading = false;
//                     });
//                   }
//                 }
//
//                 Widget _buildTile(InstalledApp app) {
//                   final subtitle = app.systemApp ? 'System app' : 'User app';
//
//                   return Card(
//                     margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     child: ListTile(
//                       leading: app.icon != null
//                           ? Image.memory(app.icon!, width: 40, height: 40)
//                           : const Icon(Icons.apps),
//                       title: Text(app.appName),
//                       subtitle: Text('${app.packageName} • $subtitle'),
//                       trailing: const Icon(Icons.chevron_right),
//                       onTap: () async {
//                         final pkg = app.packageName;
//                         final intentUri = 'intent://#Intent;package=$pkg;end';
//                         final playStore = 'https://play.google.com/store/apps/details?id=$pkg';
//                         try {
//                           final launched = await launchUrlString(intentUri, mode: LaunchMode.externalApplication);
//                           if (!launched) await launchUrlString(playStore, mode: LaunchMode.externalApplication);
//                         } catch (_) {
//                           await launchUrlString(playStore, mode: LaunchMode.externalApplication);
//                         }
//                       },
//                     ),
//                   );
//                 }
//
//                 @override
//                 Widget build(BuildContext context) {
//                   return Scaffold(
//                     appBar: AppBar(title: const Text('Installed Apps')),
//                     body: _loading
//                         ? const Center(child: CircularProgressIndicator())
//                         : _apps.isEmpty
//                             ? const Center(child: Text('No apps found'))
//                             : ListView.builder(
//                                 itemCount: _apps.length,
//                                 itemBuilder: (context, index) => _buildTile(_apps[index]),
//                               ),
//                   );
//                 }
//               }
