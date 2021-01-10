import 'package:geolocator/geolocator.dart';
import 'package:whats_in_my_masjid/serviceLocator.dart';
import 'package:whats_in_my_masjid/services/LocalStorageService.dart';

class MapPreferences {
  static bool isLocationAvailable;
  static String notification;
}

//First Step
Future<MapPreferences> initialiseMapSettings() async {
  LocationPermission permission;
  //Check if user wants to share location
  if (locator<LocalStorageService>().useLocation) {
    permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      if (await Geolocator.isLocationServiceEnabled()) {
        MapPreferences.isLocationAvailable = true;
        MapPreferences.notification = "Fetching Location";
        return Future<MapPreferences>.value(MapPreferences());
      } else {
        //Create map with last searched position and a "Notification Service Disabled" notification
        MapPreferences.isLocationAvailable = false;
        MapPreferences.notification =
            "Device Location is not enabled. Running in No Location mode";
        return Future<MapPreferences>.value(MapPreferences());
      }
    } else {
      //Create map with last searched position and a "Location Access Denied" notification
      MapPreferences.isLocationAvailable = false;
      MapPreferences.notification =
          "Location access denied. Running in No Location mode";
      return Future<MapPreferences>.value(MapPreferences());
    }
  } else {
    MapPreferences.isLocationAvailable = false;
    MapPreferences.notification = " Running in No Location mode";
    return Future<MapPreferences>.value(MapPreferences());
  }
}
