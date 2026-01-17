import 'package:flutter/material.dart';
import 'ip_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Privacy App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const IpPage(),
    );
  }
}
