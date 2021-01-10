import 'dart:convert';
import 'package:whats_in_my_masjid/local.properties';
import 'package:whats_in_my_masjid/serviceLocator.dart';
import 'package:whats_in_my_masjid/services/LocalStorageService.dart';

import 'services/google_maps.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator().then((val) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "What's in my Masjid",
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MasjidMaps(),
    );
  }
}

class MasjidMaps extends StatefulWidget {
  MasjidMaps({Key key}) : super(key: key);

  @override
  _MasjidMapsState createState() => _MasjidMapsState();
}

class _MasjidMapsState extends State<MasjidMaps> {
  Iterable markers = [];
  LatLng _lastMapPosition = LatLng(locator<LocalStorageService>().latitude,
      locator<LocalStorageService>().longitude);
  // LatLng _lastMapPosition;

  @override
  void initState() {
    super.initState();
    // getPlaces(latLng);
    initialiseMapSettings();
    // getCurrentPosition().then((val) => getPlaces(val));
  }

  getPlaces(LatLng latLng, BuildContext context, double radius) async {
    try {
      final response = await http.get(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latLng.latitude},${latLng.longitude}&radius=$radius&type=mosque&fields=name&key=$MAPS_API_KEY');

      final int statusCode = response.statusCode;

      if (statusCode == 201 || statusCode == 200) {
        Map responseBody = json.decode(response.body);
        List results = responseBody["results"];

        Iterable _markers = Iterable.generate(results.length, (index) {
          Map result = results[index];
          Map location = result["geometry"]["location"];
          LatLng latLngMarker = LatLng(location["lat"], location["lng"]);

          return Marker(
              markerId: MarkerId("marker$index"),
              position: latLngMarker,
              icon: BitmapDescriptor.defaultMarker);
        });
        Scaffold.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(_markers.length.toString() + ' Masajid Found'),
        ));

        setState(() {
          markers = _markers;
        });
      } else {
        throw Exception('Error');
      }
    } catch (e) {
      print('ERROR______________________' + e.toString());
    }
  }

  getCurrentPosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);
    setState(() {
      _lastMapPosition = LatLng(position.latitude, position.longitude);
    });
    return _lastMapPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildMap(_lastMapPosition, markers),
    );
  }

  Widget buildMap(LatLng latLng, Iterable masajids) {
    Future<LatLngBounds> screenLatLng;
    return Stack(
      children: [
        GoogleMap(
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: Set.from(
            masajids,
          ),
          initialCameraPosition: CameraPosition(target: latLng, zoom: 15.0),
          onCameraMove: (position) {
            _lastMapPosition = position.target;
          },
          mapType: MapType.normal,
          onMapCreated: (GoogleMapController controller) {
            screenLatLng = controller.getVisibleRegion();
          },
        ),
        Builder(builder: (context) {
          return Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: FlatButton(
                color: Colors.white,
                child: Text('Search Here'),
                onPressed: () async {
                  LatLngBounds screenEdges = await screenLatLng;
                  getPlaces(_lastMapPosition, context, getRadius(screenEdges));
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  double getRadius(LatLngBounds screenEdges) {
    return 1500;
    // return min(
    //     Geolocator.distanceBetween(screenEdges.northeast.latitude, 0,
    //         screenEdges.southwest.latitude, 0),
    //     Geolocator.distanceBetween(0, screenEdges.northeast.longitude, 0,
    //         screenEdges.southwest.longitude));
  }
}
