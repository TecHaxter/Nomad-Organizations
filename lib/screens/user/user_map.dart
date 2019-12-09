import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nomad/screens/drawer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart' as prefix0;
import 'package:location/location.dart';

class UserMap extends StatefulWidget {
  final String institute;
  final String bus;
  final String name;
  final String userID;
  final String uid;
  UserMap(this.institute, this.bus, this.name, this.userID, this.uid);

  @override
  State<StatefulWidget> createState() {
    return UserMapState();
  }
}

class UserMapState extends State<UserMap> {

  GoogleMapController mapController;

  Map<PolylineId, Polyline> _mapPolylines = {};
  int _polylineIdCounter = 1;

  final List<LatLng> points = <LatLng>[];

  Set<Marker> _markers = {};

  LatLng _lastMapPosition; // CLASS MEMBER, MAP OF MARKS
  bool driver_status = false;
  bool pick_request = false;

  GeoFirePoint _driverCurrentLocation;        

  Geoflutterfire geo = Geoflutterfire();

  var firestore = Firestore.instance;

  BitmapDescriptor myIcon;
  BorderRadiusGeometry radius;

  prefix0.Position currentLocation;
  LatLng _center ;

  Location location = Location();

  Future<prefix0.Position> locateUser() async {
    return prefix0.Geolocator()
        .getCurrentPosition(desiredAccuracy: prefix0.LocationAccuracy.best);
  }

  getUserLocation() async {
    currentLocation = await locateUser();
    setState(() {
      _center = LatLng(currentLocation.latitude, currentLocation.longitude);
    });
    print('center $_center');
  }

  getRoute() {
    firestore
      .collection(widget.institute)
      .document(widget.bus)
      .collection('Route')
      .orderBy('serial')
      .snapshots()
      .listen(
        (snap)  => snap.documents.forEach((doc){
          print(doc.data['LatLng'].latitude.toString());
          points.add(LatLng(doc.data['LatLng'].latitude, doc.data['LatLng'].longitude));                   
        }),
      );
  }

  pickupRequest(bool value) async {
    await location.getLocation();
    if(value == true) {
      var pos = await locateUser();
      GeoFirePoint point  = geo.point(latitude: pos.latitude, longitude: pos.longitude);
      firestore.collection(widget.institute).document(widget.bus).collection('Users').document(widget.uid).updateData({
        'position': point.data,
        'pickup': value,
      });
    } else {
      firestore.collection(widget.institute).document(widget.bus).collection('Users').document(widget.uid).updateData({
        'pickup': value,
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getRoute();
    getUserLocation();
    // WidgetsBinding.instance
    //     .addPostFrameCallback((_) => firstLocation());
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)), 'assets/bus_icon.png')
        .then((onValue) {
          myIcon = onValue;
    });
    radius = BorderRadius.only(
      topLeft: Radius.circular(12.0),
      topRight: Radius.circular(12.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _center == null ? Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            backgroundColor: Colors.black,
          ),
        ),
      ) : Scaffold(
        appBar: AppBar(
          title: Text("Nomad"),
        ),
        drawer: DrawerWidget(name: widget.name, userID: widget.userID, institute: widget.institute,),
        body: SlidingUpPanel(
          panel: StreamBuilder(
            stream: firestore.collection(widget.institute.toString()).document(widget.bus.toString()).collection("Driver").snapshots(),
            builder: (context, snap) {
              if(snap.hasData) {
                List<DocumentSnapshot> snapshot = snap.data.documents;
                if(snapshot[0]['session'] == true)
                {
                  _lastMapPosition = LatLng(snapshot[0]['location']['geopoint'].latitude, snapshot[0]['location']['geopoint'].longitude);
                  print(snapshot[0]['location']['geopoint'].latitude.toString());
                  this._driverCurrentLocation = geo.point(latitude: snapshot[0]['location']['geopoint'].latitude, longitude: snapshot[0]['location']['geopoint'].longitude);
                  print(_driverCurrentLocation.data['geopoint'].latitude.toString() + " " + _driverCurrentLocation.data['geopoint'].longitude.toString());
                  this.driver_status = true;
                  _getDriverMarker(_driverCurrentLocation.data['geopoint'].latitude, _driverCurrentLocation.data['geopoint'].longitude);
                  
                  return Container(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: Text(
                              "Driver Name : " + snapshot[0]['name'] + "\n" + "Contact Driver : " + snapshot[0]['contact'],
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.w300)
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  this.driver_status = false;
                  _getDriverMarker(0.0, 0.0);
                  return Container(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: Text(
                              "Driver Name : " + snapshot[0]['name'] + "\n" + "Contact Driver : " + snapshot[0]['contact'],
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.w300)
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              } else {
                return Container(
                    child: Center(child: CircularProgressIndicator(),),
                );
              }
            },
          ),
          collapsed: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: radius,
            ),
            child: Center(
              child: driver_status == true ?
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Driver Online",
                    style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.w300),
                  ),
                  StreamBuilder(
                    stream: firestore.collection(widget.institute).document(widget.bus).collection('Users').document(widget.uid).snapshots(),
                    builder: (context, snap) {
                      if(snap.hasData) {
                        if(snap.data['pickup'] == false) {
                          return MaterialButton(
                            child: Text(
                              "Pickup", 
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w300)
                            ),
                            color: Colors.blueAccent,
                            onPressed: () {
                              _addOrRemoveMarker(true);
                            },
                          );
                        } else {
                          return MaterialButton(
                            child: Text(
                              "I am Riding", 
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w300)
                            ),
                            color: Colors.blueAccent,
                            onPressed: () {
                              _addOrRemoveMarker(false);
                            },
                          );
                        }
                      } else {
                        return CircularProgressIndicator(backgroundColor: Colors.blueAccent,);
                      }
                    },
                  ),
                ],
              ) :
              Text(
                "Driver Offline",
                style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.w300),
              ),
            ),
          ),
          body: Stack(
            children: <Widget>[
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_center.latitude, _center.longitude),
                  zoom: 15
                ),
                rotateGesturesEnabled: true,
                compassEnabled: true,
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
                polylines: Set<Polyline>.of(_mapPolylines.values),
                markers: _markers,
              ),
            ],
          ),
          backdropEnabled: true,
          borderRadius: radius,
        )
      );
  }

  void _addRoutePoints() {
    final String polylineIdVal = 'polyline_id_$_polylineIdCounter';
    _polylineIdCounter++;
    final PolylineId polylineId = PolylineId(polylineIdVal);

    final Polyline polyline = Polyline(
      polylineId: polylineId,
      consumeTapEvents: true,
      color: Colors.grey,
      width: 10,
      points: points,
    );

    setState(() {
      _mapPolylines[polylineId] = polyline;
    });
  }

  _getDriverMarker(lat, long) async{
    if(driver_status == true) {
      SchedulerBinding.instance.addPostFrameCallback((_) => setState(() {
          this._markers.clear();
          this._markers.add(Marker(
            markerId: MarkerId(_lastMapPosition.toString()),
            icon: myIcon,
            position: LatLng(lat, long),
          )); 
      }));
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => setState(() {
          this._markers.clear();  
      }));
    }
  }

  void _addOrRemoveMarker(bool value) {
    SchedulerBinding.instance.addPostFrameCallback((_) => setState(() {
        this.pick_request = value;
        pickupRequest(value); 
    }));
  }

  _onMapCreated(GoogleMapController controller) {
    _addRoutePoints();
    setState(() {
      mapController = controller;
    });
  }

}
