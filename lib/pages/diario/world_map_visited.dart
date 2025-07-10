import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/viaggio.dart';

class WorldMapVisited extends StatelessWidget {
  final List<Viaggio> viaggi;

  const WorldMapVisited({super.key, required this.viaggi});

  @override
  Widget build(BuildContext context) {
    final destinazioni = viaggi
        .where((v) => v.archiviato)
        .map((v) => _getLatLng(v.destinazione))
        .where((coord) => coord != null)
        .cast<LatLng>()
        .toList();

    return SizedBox(
      height: 300,
      child: FlutterMap(
        options: MapOptions(
          center: LatLng(20, 0),
          zoom: 2,
          interactiveFlags: InteractiveFlag.all,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.travel_sage',
          ),
        MarkerLayer(
                  markers: destinazioni.map((latlng) {
                    return Marker(
                      point: latlng,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.indigo,
                        size: 30,
                      ),
                    );
                  }).toList(),
        ),
        ],
      ),
    );
  }

  LatLng? _getLatLng(String destinazione) {
    final mappa = {
      'Tokyo': LatLng(35.6895, 139.6917),
      'Barcellona': LatLng(41.3851, 2.1734),
      'Roma': LatLng(41.9028, 12.4964),
      'New York': LatLng(40.7128, -74.0060),
      'Parigi': LatLng(48.8566, 2.3522),
      'Londra': LatLng(51.5072, -0.1276),
      'Berlino': LatLng(52.52, 13.405),
    };

    return mappa[destinazione];
  }
}
