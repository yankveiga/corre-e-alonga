import 'package:geolocator/geolocator.dart';
import '../domain/location.dart';

class DeviceLocation implements LocationService {
  @override
  Future<void> requestAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Ative a localização do aparelho e tente novamente.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Localização bloqueada. Autorize nas configurações do aparelho.',
      );
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw StateError(
        'Permissão de localização negada. Você pode treinar sem GPS.',
      );
    }
  }

  @override
  Stream<TrackPoint> positions() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    ),
  ).map((p) => TrackPoint(p.latitude, p.longitude, p.accuracy, p.timestamp));
}
