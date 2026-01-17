# Code Examples - Download Notification Feature

## Basic Usage Examples

### 1. Initialize Notifications (in main.dart or app init)

```dart
import 'package:privacy_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  await NotificationService().initialize(
    onTap: (response) {
      // Handle notification tap
      if (response.payload != null) {
        print('Tapped notification: ${response.payload}');
      }
    },
  );
  
  runApp(const MyApp());
}
```

### 2. Show Download Notification

```dart
// After generating and saving PDF
await NotificationService().showDownloadNotification(
  fileName: 'Privacy_Report_1705434567890.pdf',
  filePath: '/storage/emulated/0/Download/Privacy_Report_1705434567890.pdf',
);
```

### 3. Open PDF from Notification

```dart
// Automatically called when notification is tapped
// Or manually:
await NotificationService().openFile(filePath);
```

## Complete Report Generation Example

### Before Implementation
```dart
Future<void> _generateAndSharePDF() async {
  try {
    // ... PDF generation code ...
    
    final dir = await getDownloadsDirectory();
    if (dir != null) {
      final file = File('${dir.path}/Privacy_Report.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Old: Only showed snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to ${file.path}')),
        );
      }
    }
  } catch (e) {
    // Error handling
  }
}
```

### After Implementation
```dart
Future<void> _generateAndSharePDF() async {
  try {
    // ... PDF generation code ...
    
    final dir = await getDownloadsDirectory();
    if (dir != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Privacy_Report_$timestamp.pdf';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      
      await file.writeAsBytes(await pdf.save());
      
      // New: Shows notification with tap-to-open functionality
      await NotificationService().showDownloadNotification(
        fileName: fileName,
        filePath: filePath,
      );
    }
  } catch (e) {
    // Error handling
  }
}
```

## Notification Service API

### Class: NotificationService

#### Singleton Pattern
```dart
// Get instance
final notificationService = NotificationService();

// Same instance everywhere
NotificationService().showDownloadNotification(...);
NotificationService().openFile(...);
```

#### Methods

**1. initialize()**
```dart
Future<void> initialize({
  required Function(NotificationResponse) onTap,
}) async
```
- Initializes notification system
- Sets up Android and iOS specific handlers
- Registers callback for notification taps
- Should be called once during app startup

Example:
```dart
await NotificationService().initialize(
  onTap: (response) {
    if (response.payload?.isNotEmpty ?? false) {
      NotificationService().openFile(response.payload!);
    }
  },
);
```

**2. showDownloadNotification()**
```dart
Future<void> showDownloadNotification({
  required String fileName,
  required String filePath,
}) async
```
- Shows download notification
- Uses system-native notification display
- Tapping opens the file
- Automatically includes timestamp

Example:
```dart
await NotificationService().showDownloadNotification(
  fileName: 'Report.pdf',
  filePath: '/storage/Download/Report.pdf',
);
```

**3. openFile()**
```dart
Future<void> openFile(String filePath) async
```
- Opens file with system default viewer
- Uses `url_launcher` package
- Handles errors gracefully
- Works for any file type

Example:
```dart
await NotificationService().openFile('/storage/Download/Report.pdf');
```

## Platform-Specific Configuration

### Android Notification Details

```dart
const AndroidNotificationDetails(
  'download_channel',           // Channel ID
  'Downloads',                  // Channel name
  importance: Importance.max,   // Importance level
  priority: Priority.high,      // Priority level
  enableVibration: true,        // Vibration enabled
  playSound: true,              // Sound enabled
  showProgress: false,          // Progress indicator
  channelShowBadge: true,       // Badge on icon
)
```

### iOS Notification Details

```dart
const DarwinNotificationDetails(
  presentAlert: true,   // Show alert
  presentBadge: true,   // Update badge
  presentSound: true,   // Play sound
)
```

## Error Handling Patterns

### Pattern 1: Graceful Degradation
```dart
try {
  await NotificationService().showDownloadNotification(
    fileName: fileName,
    filePath: filePath,
  );
} catch (e) {
  // Log error but don't crash
  debugPrint('Notification error: $e');
  
  // File is still saved even if notification fails
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('File saved: $fileName')),
  );
}
```

### Pattern 2: File Validation
```dart
Future<void> _showNotificationIfFileExists(String filePath) async {
  final file = File(filePath);
  
  if (await file.exists()) {
    final size = await file.length();
    
    if (size > 0) {
      await NotificationService().showDownloadNotification(
        fileName: file.path.split('/').last,
        filePath: filePath,
      );
    }
  }
}
```

### Pattern 3: Safe File Opening
```dart
void _handleNotificationTap(NotificationResponse response) {
  if (response.payload?.isNotEmpty ?? false) {
    try {
      NotificationService().openFile(response.payload!);
    } catch (e) {
      _showErrorDialog('Could not open file: $e');
    }
  }
}
```

## Integration with Existing Code

### In ReportPage
```dart
class _ReportPageState extends State<ReportPage> {
  
  @override
  void initState() {
    super.initState();
    _initializeNotifications(); // Initialize on page load
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
  
  Future<void> _generateAndSharePDF() async {
    // ... existing PDF generation code ...
    
    // After saving PDF
    await NotificationService().showDownloadNotification(
      fileName: fileName,
      filePath: filePath,
    );
  }
}
```

### In Other Pages
```dart
// Simply use notification service in any page
onPressed: () async {
  final dir = await getDownloadsDirectory();
  final file = File('${dir?.path}/report.pdf');
  
  // Save file here...
  
  // Show notification
  await NotificationService().showDownloadNotification(
    fileName: 'report.pdf',
    filePath: file.path,
  );
}
```

## Testing Examples

### Unit Test Mock
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NotificationService is singleton', () {
    final service1 = NotificationService();
    final service2 = NotificationService();
    
    expect(identical(service1, service2), true);
  });
}
```

### Widget Test
```dart
testWidgets('PDF notification shown on generation', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Navigate to report page
  await tester.tap(find.text('Reports'));
  await tester.pumpAndSettle();
  
  // Generate report
  await tester.tap(find.text('Generate Report'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Verify notification service was called
  // (This requires mocking the notification service)
});
```

## Common Use Cases

### 1. Download Multiple Files
```dart
List<String> fileNames = ['Report.pdf', 'Summary.pdf'];
List<String> filePaths = [path1, path2];

for (int i = 0; i < fileNames.length; i++) {
  await NotificationService().showDownloadNotification(
    fileName: fileNames[i],
    filePath: filePaths[i],
  );
}
```

### 2. Download with Progress
```dart
// Show initial notification
await NotificationService().showDownloadNotification(
  fileName: 'Large_Report.pdf',
  filePath: filePath,
);

// After download completes, show another notification
await NotificationService().showDownloadNotification(
  fileName: 'Large_Report.pdf (Completed)',
  filePath: filePath,
);
```

### 3. Share from Notification
```dart
void _handleNotificationTap(NotificationResponse response) {
  if (response.payload != null) {
    // Could extend to show share options
    _shareFile(response.payload!);
  }
}

Future<void> _shareFile(String filePath) async {
  // Use share_plus package to share
  // await Share.shareFiles([filePath]);
}
```

## Performance Considerations

### Memory Efficient
```dart
// Good: Singleton pattern
final service = NotificationService();
service.showDownloadNotification(...);
service.openFile(...);

// Avoid: Creating multiple instances
final s1 = NotificationService();
final s2 = NotificationService(); // Same instance (singleton)
```

### Battery Efficient
```dart
// Good: Minimal vibration/sound settings
const AndroidNotificationDetails(
  'channel',
  'Downloads',
  enableVibration: true,    // Short vibration only
  playSound: true,          // System sound only
)

// Avoid: Excessive notifications
// Don't call showDownloadNotification for every small file
```

---

## Quick Reference Card

| Task | Code |
|------|------|
| Initialize | `await NotificationService().initialize(onTap: ...)` |
| Show Notification | `await NotificationService().showDownloadNotification(...)` |
| Open File | `await NotificationService().openFile(path)` |
| Get Instance | `NotificationService()` |
| Is Singleton | Yes, always same instance |

---

**Documentation Version:** 1.0
**Last Updated:** January 16, 2026
