import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nomad/screens/user/user_map.dart';
import 'package:nomad/screens/driver/driver_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UIScreen extends StatefulWidget {

  const UIScreen({Key key, this.userUID}) : super(key: key);
  final Future<String> userUID;

  @override
  State<StatefulWidget> createState() {
    return UIScreenState();
  }
}

class UIScreenState extends State<UIScreen> {

  String bus;
  String institute;
  String type;
  String name;
  String userID;
  String uid;

  final List<LatLng> points = <LatLng>[];

  getUserProfile() {
    UserModel theUser;
    FirebaseAuth.instance.currentUser().then((user) {
      Firestore.instance
        .collection('/users')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .listen((data) {
          print('getting data');
          theUser = new UserModel(data.documents[0]['bus'], data.documents[0]['institute'], data.documents[0]['name'], data.documents[0]['type'], user.uid, data.documents[0]['user_id'],);
          print('got data');
          print("{$theUser._type}");
          setState(() {
            this.name = theUser._name;
            this.userID = theUser._user_id;
            this.bus = theUser._bus;
            this.institute = theUser._institute;
            this.bus = theUser._bus;
            this.type = theUser._type;
            this.uid = theUser._uid;
          });
        });
    }).catchError((e) {
      print("there was an error");
      print(e);
    });
  }

  @override
  void initState() {
    super.initState();
    getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    if(this.type != null) {
      if(type == "Users") {
        print("Users");
        return UserMap(institute, bus, name, userID, uid);
      } else {
        print("Driver");
        return DriverMap(institute, bus, name, userID);
      }
    }
    return Scaffold(body: CircularProgressIndicator(),);
  }
}

class UserModel {
  String _bus, _institute, _name, _type, _uid, _user_id;
  UserModel(this._bus, this._institute, this._name, this._type, this._uid, this._user_id);
}
