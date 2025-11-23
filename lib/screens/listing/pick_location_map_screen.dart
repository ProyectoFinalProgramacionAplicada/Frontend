import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PickLocationMapScreen extends StatefulWidget {
  final LatLng initialPosition;

  const PickLocationMapScreen({super.key, required this.initialPosition});

  @override
  State<PickLocationMapScreen> createState() => _PickLocationMapScreenState();
}

class _PickLocationMapScreenState extends State<PickLocationMapScreen> {
  late LatLng _selectedPosition;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    // Selecciona URL de tiles según plataforma
    final tileUrl = kIsWeb
        ? "https://tile.openstreetmap.org/{z}/{x}/{y}.png" // puede fallar en algunos navegadores por CORS
        : "https://tile.openstreetmap.org/{z}/{x}/{y}.png"; // Mobile

    return Scaffold(
      appBar: AppBar(title: const Text("Seleccionar ubicación")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: 15,
              onTap: (tapPosition, latlng) {
                setState(() => _selectedPosition = latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.truekapp.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () {
                Navigator.pop(context, _selectedPosition);
              },
              child: const Text(
                "Confirmar ubicación",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
