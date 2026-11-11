import 'dart:math' as math;

class TrackPoint {
  final double latitude, longitude, accuracy;
  final DateTime time;
  final bool segmentStart;
  const TrackPoint(
    this.latitude,
    this.longitude,
    this.accuracy,
    this.time, {
    this.segmentStart = false,
  });
  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lon': longitude,
    'accuracy': accuracy,
    'time': time.toUtc().toIso8601String(),
    'segment': segmentStart,
  };
  factory TrackPoint.fromJson(Map<String, dynamic> j) => TrackPoint(
    (j['lat'] as num).toDouble(),
    (j['lon'] as num).toDouble(),
    (j['accuracy'] as num).toDouble(),
    DateTime.parse(j['time'] as String),
    segmentStart: j['segment'] as bool,
  );
}

abstract interface class LocationService {
  // Solicita somente permissão durante uso. Falhas são comunicadas à UI.
  Future<void> requestAccess();
  Stream<TrackPoint> positions();
}

class RouteTracker {
  final List<TrackPoint> _points;
  double meters;
  bool _break = true;
  RouteTracker({List<TrackPoint> points = const [], this.meters = 0})
    : _points = List.of(points);
  List<TrackPoint> get points => List.unmodifiable(_points);
  void breakSegment() {
    _break = true;
  }

  bool add(TrackPoint point, DateTime now) {
    if (!point.latitude.isFinite ||
        !point.longitude.isFinite ||
        !point.accuracy.isFinite ||
        point.latitude.abs() > 90 ||
        point.longitude.abs() > 180 ||
        point.accuracy < 0 ||
        point.accuracy > 35 ||
        now.difference(point.time).inSeconds > 15 ||
        point.time.difference(now).inSeconds > 3) {
      _break = true;
      return false;
    }
    var start = _break || _points.isEmpty;
    var distance = 0.0;
    if (_points.isNotEmpty) {
      final last = _points.last;
      final dt = point.time.difference(last.time).inMilliseconds / 1000;
      if (dt <= 0) return false;
      if (dt > 30) start = true;
      distance = distanceMeters(last, point);
      // Uma corrida não deve somar teleportes ou jitter parado.
      if (!start && distance / dt > 12) {
        _break = true;
        return false;
      }
      if (!start &&
          distance <
              math.max(5, math.min(point.accuracy, last.accuracy) * .5)) {
        return false;
      }
    }
    if (!start) meters += distance;
    _points.add(
      TrackPoint(
        point.latitude,
        point.longitude,
        point.accuracy,
        point.time,
        segmentStart: start,
      ),
    );
    _break = false;
    return true;
  }
}

double distanceMeters(TrackPoint a, TrackPoint b) {
  const rad = math.pi / 180;
  final dLat = (b.latitude - a.latitude) * rad,
      dLon = (b.longitude - a.longitude) * rad;
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(a.latitude * rad) *
          math.cos(b.latitude * rad) *
          math.pow(math.sin(dLon / 2), 2);
  return 6371000 * 2 * math.asin(math.sqrt(h.clamp(0, 1)));
}

String distanceLabel(double meters, String unit) =>
    '${(meters / (unit == 'mi' ? 1609.344 : 1000)).toStringAsFixed(2)} $unit';
String paceLabel(double meters, Duration duration, String unit) {
  if (meters < 100 || duration.inSeconds < 1) return '— /$unit';
  final seconds =
      (duration.inSeconds / (meters / (unit == 'mi' ? 1609.344 : 1000)))
          .round();
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} /$unit';
}

/// Returns whether a GPS trace forms a meaningful closed loop.
bool isClosedLoop(List<TrackPoint> points, {double toleranceMeters = 120}) {
  final usable = points.where((p) => p.segmentStart || true).toList();
  if (usable.length < 4) return false;
  final first = usable.first;
  final last = usable.last;
  return distanceMeters(first, last) <= toleranceMeters;
}

/// Approximate area enclosed by a trace in square metres using a local
/// equirectangular projection. This is intentionally local and deterministic;
/// a server is required for competitive ownership and conflict resolution.
double enclosedAreaSquareMeters(List<TrackPoint> points) {
  if (!isClosedLoop(points)) return 0;
  final lat0 =
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
  const r = 6371000.0;
  final cosLat = math.cos(lat0 * math.pi / 180);
  final projected = points.map(
    (p) => (
      x: p.longitude * math.pi / 180 * r * cosLat,
      y: p.latitude * math.pi / 180 * r,
    ),
  );
  var sum = 0.0;
  for (var i = 0; i < projected.length; i++) {
    final a = projected.elementAt(i);
    final b = projected.elementAt((i + 1) % projected.length);
    sum += a.x * b.y - b.x * a.y;
  }
  return sum.abs() / 2;
}
