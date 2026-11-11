import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../domain/location.dart';

class RouteMap extends StatefulWidget {
  final List<TrackPoint> points;
  const RouteMap({super.key, required this.points});
  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  bool online = false;
  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const Text(
        'O percurso aparece após receber posições GPS confiáveis.',
      );
    }
    final segments = <List<LatLng>>[];
    for (final point in widget.points) {
      if (segments.isEmpty || point.segmentStart) segments.add([]);
      segments.last.add(LatLng(point.latitude, point.longitude));
    }
    final points = segments.expand((s) => s).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              key: ValueKey(online),
              options: MapOptions(
                initialCenter: points.first,
                initialZoom: 15,
                initialCameraFit: points.length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(points),
                        padding: const EdgeInsets.all(30),
                        maxZoom: 17,
                      )
                    : null,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              children: [
                if (online)
                  TileLayer(
                    urlTemplate: const String.fromEnvironment(
                      'MAP_TILE_URL',
                      defaultValue:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    userAgentPackageName: 'br.com.correealonga.corre_alonga',
                    maxZoom: 19,
                  ),
                PolylineLayer(
                  polylines: [
                    for (final segment in segments)
                      if (segment.length > 1)
                        Polyline(
                          points: segment,
                          strokeWidth: 5,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: points.last,
                      width: 32,
                      height: 32,
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF865000),
                        size: 30,
                      ),
                    ),
                  ],
                ),
                if (online)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.all(6),
                      child: const Text(
                        '© OpenStreetMap contributors\nopenstreetmap.org/copyright',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mapa de base online'),
          subtitle: const Text(
            'Consulta OpenStreetMap e compartilha a área exibida com o provedor. Sem conexão, seu traçado local continua disponível.',
          ),
          value: online,
          onChanged: (value) => setState(() {
            online = value;
          }),
        ),
      ],
    );
  }
}
