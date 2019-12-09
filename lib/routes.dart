import 'package:flutter/material.dart';
import 'package:nomad/screens/screen.dart';
import './screens/sign_in.dart';
import './screens/auth.dart'; 
import './services/auth_provider.dart';

class RootPage extends StatelessWidget {
 
  @override
  Widget build(BuildContext context) {
    final BaseAuth auth = AuthProvider.of(context).auth;
    return StreamBuilder<String>(
      stream: auth.onAuthStateChanged,
      builder: (BuildContext context, snapshot) {
        if(snapshot.connectionState == ConnectionState.active) {
          final bool isLoggedIn = snapshot.hasData;
          return isLoggedIn ? UIScreen(userUID: auth.currentUser()) : LoginPage();
        }
        return _buildWaitingScreen();
      },
    );
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    );
  }

}