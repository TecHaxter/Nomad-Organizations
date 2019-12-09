import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nomad/screens/drawer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:geolocator/geolocator.dart' as prefix0;
import 'package:location/location.dart';

class DriverMap extends StatefulWidget {
  final String institute;
  final String bus;
  final String name;
  final String userID;
  DriverMap(this.institute, this.bus, this.name, this.userID);

  @override
  State<StatefulWidget> createState() {
    return DriverMapState();
  }
}

class DriverMapState extends State<DriverMap> {

  GoogleMapController mapController;

  Map<PolylineId, Polyline> _mapPolylines = {};
  int _polylineIdCounter = 1;

  final List<LatLng> points = <LatLng>[];

  GeoFirePoint _currentLocation;        

  Geoflutterfire geo = Geoflutterfire();
  Firestore _firestore = Firestore.instance;

  Set<Marker> _markers = {};

  prefix0.Position currentLocation;
  LatLng _center ;

  Location location = Location();
 
  //Get the route and add it to the points variable
  getRoute(){
    _firestore
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

  sendLocation() async {
    //listen to the stream of location
    location.getLocation();
    prefix0.Geolocator().getPositionStream().listen((prefix0.Position position) {
      //sets the value of variable to upload to database
      // setState(() {
        _currentLocation = geo.point(latitude: position.latitude, longitude: position.longitude);
      // });
      //firestore called for upload
      _firestore
            .collection(widget.institute)
            .document(widget.bus)
            .collection("Driver")
            .document("1")
            .updateData({'location' : _currentLocation.data})
            .catchError((e) {
          print(e);
      });
      //Sets the changing location in the Map Controller
      LatLng latLng = new LatLng(position.latitude, position.longitude);
      CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(latLng, 15);
      mapController.animateCamera(cameraUpdate);
    });
  }

  getUserMarker() async {
    _firestore
      .collection(widget.institute)
      .document(widget.bus)
      .collection('Users')
      .snapshots()
      .listen(
        (snap)  => snap.documents.forEach((doc){
          //adds the marker if user wants to pick up
          if(doc.data['pickup'] == true) {
            // print('Marker Added' + doc.data['name'].toString());
            setState(() {
              _markers.add(Marker(
                markerId: MarkerId(doc.data['uid'].toString()),
                icon: BitmapDescriptor.defaultMarker,
                position: LatLng(doc.data['position']['geopoint'].latitude, doc.data['position']['geopoint'].longitude),
                infoWindow: InfoWindow(title: doc.data['name']),
              )); 
            });
          } else { //remove if don't
            // print('Marker Removed' + doc.data['name'].toString());
            // Marker mark = _markers.singleWhere((marker) => marker.markerId.value == doc.data['uid'].value, orElse: () => null);
            // if(mark == null) {
            //   setState(() {
            //     _markers.remove(mark);
            //   });
            // }
          }                  
        }),
      );
  }

//Giving these functions priority over the Build Refresh
@override
  void initState() {
    super.initState();
    getRoute();
    sendLocation();
  }

  @override
  Widget build(BuildContext context) {
    getUserMarker();
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(12.0),
      topRight: Radius.circular(12.0),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text("Nomad"),
      ),
      drawer: DrawerWidget(name: widget.name, userID: widget.userID, institute: widget.institute,),
      body: SlidingUpPanel(
        //Listen for Driver's own session status
        collapsed: StreamBuilder(
          stream: _firestore.collection(widget.institute.toString()).document(widget.bus.toString()).collection("Driver").snapshots(),
          builder: (context, snap) {
            //shows End button
            if(snap.hasData) {
              List<DocumentSnapshot> snapshot = snap.data.documents;
              if(snapshot[0]['session'] == true)
              { 
                return MaterialButton(
                    child: Text(
                      "End", 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w300)
                    ),
                    color: Colors.red,
                    onPressed: () {
                      updateSession(false);
                    },
                  );
              } else { //Shows Start Button
                return MaterialButton(
                    child: Text(
                      "Start", 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w300)
                    ),
                    color: Colors.green,
                    onPressed: () {
                      updateSession(true);
                    },
                  );
              }
            } else { //If session status is not recieved then ... 
              return Container(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
              );
            }
          },
        ),
        //Swipe Up panel here
        panel: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Text(
                    "Institute : "+widget.institute + "\n" + 
                    "Bus : "+widget.bus + "\n" + 
                    "Driver : "+widget.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.w300)
                  ),
                )
              ],
            ),
          ),
        ),
        //Map in Stack Widget
        body: Stack(
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(26.9124, 75.7873),
                zoom: 12
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
  //Updates session status of Driver
  void updateSession(bool value) async{
    await _firestore
        .collection(widget.institute)
        .document(widget.bus)
        .collection("Driver")
        .document("1")
        .updateData({'session' : value})
        .catchError((e) {
      print(e);
    });
  }

  //Recieved points are added in polyline
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

  //Called when map is created, call the add Route Point function
  _onMapCreated(GoogleMapController controller) {
    _addRoutePoints();
    setState(() {
      mapController = controller;
    });
  }

}