import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'pages/reports.dart';
import 'pages/vin_entry.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Vehicle Management',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => HomePage(title: 'Vehicle Management'),
          '/vin-entry': (context) => VinEntryPage(),
          '/reports': (context) => ReportsPage(),
        });
  }
}
