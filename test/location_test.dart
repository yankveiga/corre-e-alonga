import 'package:flutter_test/flutter_test.dart';
import 'package:corre_alonga/domain/location.dart';
import 'package:corre_alonga/domain/session.dart';
import 'session_test.dart' show fixture;

void main() {
  test('identifica e mede um circuito fechado', () {
    final t = DateTime(2026);
    final points = [
      TrackPoint(-23.5500, -46.6300, 5, t),
      TrackPoint(-23.5500, -46.6200, 5, t.add(const Duration(seconds: 10))),
      TrackPoint(-23.5600, -46.6200, 5, t.add(const Duration(seconds: 20))),
      TrackPoint(-23.5500, -46.6300, 5, t.add(const Duration(seconds: 30))),
    ];
    expect(isClosedLoop(points), isTrue);
    expect(enclosedAreaSquareMeters(points), greaterThan(100000));
  });
  final start = DateTime.utc(2026, 10, 17);
  TrackPoint point(double lon, int seconds, {double accuracy = 5}) =>
      TrackPoint(0, lon, accuracy, start.add(Duration(seconds: seconds)));
  test(
    'GPS soma posições válidas, ignora jitter e separa pausas e perda de sinal',
    () {
      final route = RouteTracker();
      expect(route.add(point(0, 0), start), true);
      expect(
        route.add(point(.00001, 2), start.add(const Duration(seconds: 2))),
        false,
      );
      route.add(point(.0001, 5), start.add(const Duration(seconds: 5)));
      expect(route.meters, closeTo(11.12, .1));
      route.breakSegment();
      route.add(point(.001, 10), start.add(const Duration(seconds: 10)));
      expect(route.meters, closeTo(11.12, .1));
      route.add(point(.002, 50), start.add(const Duration(seconds: 50)));
      expect(route.meters, closeTo(11.12, .1));
      expect(route.points.where((p) => p.segmentStart).length, 3);
    },
  );
  test('rejeita imprecisão, salto, coordenada inválida e posição antiga', () {
    final route = RouteTracker();
    route.add(point(0, 0), start);
    expect(
      route.add(point(1, 1), start.add(const Duration(seconds: 1))),
      false,
    );
    expect(
      route.add(
        point(1, 1, accuracy: 90),
        start.add(const Duration(seconds: 1)),
      ),
      false,
    );
    expect(route.add(point(181, 1), start), false);
    expect(
      route.add(point(1, 0), start.add(const Duration(seconds: 40))),
      false,
    );
    expect(route.meters, 0);
    expect(paceLabel(0, const Duration(seconds: 60), 'km'), '— /km');
    expect(paceLabel(1000, const Duration(seconds: 300), 'km'), '5:00 /km');
    expect(distanceLabel(1609.344, 'mi'), '1.00 mi');
  });
  test(
    'checkpoint e atividade preservam percurso e mantêm compatibilidade',
    () {
      final cp = SessionCheckpoint(
        's',
        fixture(),
        10000,
        start,
        points: [point(0, 0)],
        meters: 12.5,
      );
      final decoded = SessionCheckpoint.fromJson(cp.toJson());
      expect(decoded.points.single.latitude, 0);
      expect(decoded.meters, 12.5);
      final old = cp.toJson()
        ..remove('points')
        ..remove('meters');
      expect(SessionCheckpoint.fromJson(old).points, isEmpty);
    },
  );
}
