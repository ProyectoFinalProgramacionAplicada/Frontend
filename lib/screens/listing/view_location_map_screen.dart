import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ViewLocationMapScreen extends StatefulWidget {
  final LatLng position;

  const ViewLocationMapScreen({super.key, required this.position});

  @override
  State<ViewLocationMapScreen> createState() => _ViewLocationMapScreenState();
}

class _ViewLocationMapScreenState extends State<ViewLocationMapScreen> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    const tileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";

    return Scaffold(
      appBar: AppBar(title: const Text("Ubicación del producto")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.position,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all, // mover/zoom permitido
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: "com.truekapp.app",
              ),

              // 🔵 Círculo real de 1 km
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _generateCirclePoints(widget.position, 1000),
                    color: Colors.blue.withOpacity(0.3),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),

              // 🔴 Marcador fijo
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.position,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ➕➖ Controles de zoom
          Positioned(
            right: 10,
            top: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoom_in_view",
                  onPressed: () {
                    _mapController.move(
                      _mapController.center,
                      _mapController.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoom_out_view",
                  onPressed: () {
                    _mapController.move(
                      _mapController.center,
                      _mapController.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔵 MISMA FUNCIÓN DEL PICK
  List<LatLng> _generateCirclePoints(LatLng center, double radiusInMeters) {
    const int segments = 64;
    const double earthRadius = 6378137.0;

    double lat = center.latitude * pi / 180;
    double lng = center.longitude * pi / 180;

    double angularDistance = radiusInMeters / earthRadius;
    List<LatLng> points = [];

    for (int i = 0; i <= segments; i++) {
      double bearing = 2 * pi * i / segments;

      double lat2 = asin(
        sin(lat) * cos(angularDistance) +
            cos(lat) * sin(angularDistance) * cos(bearing),
      );

      double lng2 =
          lng +
          atan2(
            sin(bearing) * sin(angularDistance) * cos(lat),
            cos(angularDistance) - sin(lat) * sin(lat2),
          );

      points.add(LatLng(lat2 * 180 / pi, lng2 * 180 / pi));
    }

    return points;
  }
}
