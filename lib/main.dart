import 'package:flutter/material.dart';
import 'package:nomad/routes.dart';
import './utils/theme_color.dart';
import 'screens/auth.dart';
import './services/auth_provider.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuthProvider(
      auth: Auth(),
      child: MaterialApp(
        title: 'Nomad',
        theme: ThemeData(
          primarySwatch: white,
        ),
        debugShowCheckedModeBanner: false,
        home: RootPage(),
      ),
    );
  }
}

