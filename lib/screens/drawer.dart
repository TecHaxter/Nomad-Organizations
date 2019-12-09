import 'package:flutter/material.dart';
import 'package:nomad/services/auth_provider.dart';
import 'package:nomad/screens/auth.dart';
import 'package:nomad/screens/find_bus.dart';
import 'dart:async';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({Key key, this.name, this.userID, this.institute}) : super(key: key);
  //final Future<String> userUID;
  //final UserModel theUser;
  final String name;
  final String userID;
  final String institute;
  
  @override
  State<StatefulWidget> createState() {
    return _DrawerWidgetState();
  }
}

class _DrawerWidgetState extends State<DrawerWidget> {

  Future<void> _signOut() async {
    if(Navigator.canPop(context)) {
      print("Navingator In");
      Navigator.pop(context);
      print("Navingator Out");
    }
    //  else {
    //   print("System Navingator In");
    //   SystemNavigator.pop();
    //   print("System Navingator Out");
    // }
    try{
      final BaseAuth auth = AuthProvider.of(context).auth;
      await auth.signOut();
    } catch (e){
    print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: new ListView(
        children: <Widget>[
          new UserAccountsDrawerHeader(
            accountEmail: new Text(widget.userID),
            accountName: new Text(widget.name),
          ),
          new ListTile(
            title: new Text("Home"),
            trailing: Icon(Icons.home),
            onTap: () => Navigator.of(context).pop(),
          ),
          new Divider(),
          new ListTile(
            title: new Text("Find Bus"),
            trailing: Icon(Icons.directions_bus),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (BuildContext context, _, __) {
                    return new FindBus(institute: widget.institute);
                  },
                  transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
                    return new FadeTransition(
                      opacity: animation,
                      child: child
                    );
                  }
                )
              );
            },
          ),
          new Divider(),
          new ListTile(
            title: new Text("Log Out"),
            trailing: Icon(Icons.exit_to_app),
            onTap: _signOut,
          ),
        ],
      )
    );
  }

}
