import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:flutter/scheduler.dart';


class FindBus extends StatefulWidget {
  final String institute;
  FindBus({Key key, this.institute}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return FindBusState();
  }
}

class FindBusState extends State<FindBus> {

  Future getBusList() async {
    var firestore = Firestore.instance;
    QuerySnapshot qn = await firestore.collection(widget.institute).getDocuments();
    return qn.documents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Find Bus"),
      ),
      //drawer: DrawerWidget(name: widget.name, institute: widget.institute, userID: widget.userID,),
      body: Container(
        child: FutureBuilder(
          future: getBusList(),
          builder: (_, snapshot) {
            if(!snapshot.hasData) {
              return Center(child: CircularProgressIndicator(backgroundColor: Colors.black,),);
            }
            else {
              return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (_, index){
                  return ListTile(
                    leading: Icon(Icons.directions_bus),
                    title: Text("Bus Number : " + snapshot.data[index].documentID.toString()),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(context, PageRouteBuilder(
                        pageBuilder: (BuildContext context, _, __) {
                          return new BusDetail(institute: widget.institute, bus: snapshot.data[index].documentID,);
                        },
                        transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
                          return new FadeTransition(
                            opacity: animation,
                            child: child
                          );
                        }
                      ));
                    },
                  );
                },
              );
            }
          },
        ),
      )
    );
  }
}

class BusDetail extends StatefulWidget {
  final String institute;
  final String bus;
  BusDetail({Key key, this.institute, this.bus}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return BusDetailState();
  }
}

class BusDetailState extends State<BusDetail> {

GoogleMapController mapController;

  Map<PolylineId, Polyline> _mapPolylines = {};
  int _polylineIdCounter = 1;

  final List<LatLng> points = <LatLng>[];

  Set<Marker> _driver_marker = {};
  LatLng _lastMapPosition; // CLASS MEMBER, MAP OF MARKS
  bool driver_status = false;

  GeoFirePoint _driverCurrentLocation;        

  Geoflutterfire geo = Geoflutterfire();

  BitmapDescriptor myIcon;

  getRoute() {
    Firestore.instance
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

  @override
  void initState() {
    super.initState();
    getRoute();
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(48, 48)), 'assets/bus_icon.png')
          .then((onValue) {
            myIcon = onValue;
          });
      
  }

  @override
  Widget build(BuildContext context) {

    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(12.0),
      topRight: Radius.circular(12.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bus),
      ),
      body: SlidingUpPanel(
        panel: StreamBuilder(
          stream: Firestore.instance.collection(widget.institute.toString()).document(widget.bus.toString()).collection("Driver").snapshots(),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: radius,
                  ),
                  height: 50,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Center(
                        child: Text(
                          "Driver Name : " + snapshot[0]['name'] + "\n" + "Contact Driver : " + snapshot[0]['contact'],
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.w300)
                        ),
                      )
                    ],
                  ),
                  //color: Colors.transparent,
                );
              } else {
                this.driver_status = false;
                _getDriverMarker(0.0, 0.0);
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: radius,
                  ),
                  height: 50,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Center(
                        child: Text(
                          "Driver Name : " + snapshot[0]['name'] + "\n" + "Contact Driver : " + snapshot[0]['contact'],
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.w300)
                        ),
                      )
                    ],
                  ),
                  //color: Colors.transparent,
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
              Text(
              "Driver Online",
              style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.w300),
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
              markers: _driver_marker,
            ),
          ],
        ),
        backdropEnabled: true,
        borderRadius: radius,
      ),
    );
  }

  void _add() {
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

  _getDriverMarker(lat, long) {
    if(driver_status == true) {
      SchedulerBinding.instance.addPostFrameCallback((_) => setState(() {
        this._driver_marker.clear();
        this._driver_marker.add(Marker(
          markerId: MarkerId(_lastMapPosition.toString()),
          icon: myIcon,
          position: LatLng(lat, long),
        ));
      })); 
      print(_driver_marker);
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => setState(() {
        this._driver_marker.clear(); 
      }));
    }
  }

  _onMapCreated(GoogleMapController controller) {
    _add();
    setState(() {
      mapController = controller;
    });
  }

}