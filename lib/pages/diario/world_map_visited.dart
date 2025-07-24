import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/viaggio.dart';
import '../viaggio_dettaglio_page.dart';

class WorldMapVisited extends StatefulWidget {
  final List<Viaggio> viaggi;
  const WorldMapVisited({super.key, required this.viaggi});

  @override
  State<WorldMapVisited> createState() => _WorldMapVisitedState();
}

class _WorldMapVisitedState extends State<WorldMapVisited> {
  final Map<String, LatLng> _cache = {};
  final PopupController _popupController = PopupController();
  List<Viaggio> _withCoord = [];

  @override
  void initState() {
    super.initState();
    _loadCoords();
  }

  Future<void> _loadCoords() async {
    final list = <Viaggio>[];
    for (var v in widget.viaggi) {
      final city = v.destinazione.trim();
      LatLng? coord = _cache[city];
      if (coord == null) {
        coord = await _geocode(city);
        if (coord != null) _cache[city] = coord;
      }
      if (coord != null) list.add(v.copyWith(coordinate: coord));
    }
    setState(() => _withCoord = list);
  }

  Future<LatLng?> _geocode(String q) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'json',
        'limit': '1',
      });
      final res = await http.get(uri, headers: {
        'User-Agent': 'TravelSageApp/1.0 (your@email)'
      });
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']);
          final lon = double.tryParse(data[0]['lon']);
          if (lat != null && lon != null) return LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _popupController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  // Se non ci sono viaggi, mostra solo la mappa senza marker
  if (_withCoord.isEmpty) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(20, 0),
              initialZoom: 2,
              minZoom: 2,
              maxZoom: 8,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.drag,
              ),
              onTap: (_, __) => _popupController.hideAllPopups(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.travel_sage',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Altrimenti, mostra la mappa con i marker
  final markers = _withCoord.map((v) {
    return Marker(
      point: v.coordinate!,
      width: 40,
      height: 40,
      child: const Icon(Icons.location_on, size: 32, color: Colors.indigo),
    );
  }).toList();

  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(18),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(20, 0),
            initialZoom: 2,
            minZoom: 2,
            maxZoom: 8,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.drag,
            ),
            onTap: (_, __) => _popupController.hideAllPopups(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.travel_sage',
            ),
            PopupMarkerLayer(
              options: PopupMarkerLayerOptions(
                markers: markers,
                popupController: _popupController,
                popupDisplayOptions: PopupDisplayOptions(
                  builder: (context, marker) {
                    final v = _withCoord.firstWhere(
                      (viaggio) => viaggio.coordinate == marker.point,
                      orElse: () => widget.viaggi.first,
                    );
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 150,  // Limita la larghezza massima
                        ),
                        child: ListTile(
                          title: Text(v.destinazione),
                          subtitle: Text("${v.dataInizio.year}"),
                          onTap: () {
                            _popupController.hideAllPopups();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViaggioDettaglioPage(
                                  viaggio: v,
                                  index: widget.viaggi.indexOf(v),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
            ],
          ),
        ),
      ),
    );
  }
}

extension on Viaggio {
  Viaggio copyWith({LatLng? coordinate}) {
    return Viaggio(
      id: id,
      userId: userId,
      titolo: titolo,
      partenza: partenza,
      destinazione: destinazione,
      dataInizio: dataInizio,
      dataFine: dataFine,
      budget: budget,
      partecipanti: partecipanti,
      confermato: confermato,
      spese: spese,
      archiviato: archiviato,
      note: note,
      interessi: interessi,
      mezzoTrasporto: mezzoTrasporto,
      attivitaGiornaliere: attivitaGiornaliere,
      raggioKm: raggioKm,
      etaMedia: etaMedia,
      tipologiaViaggiatore: tipologiaViaggiatore,
      coordinate: coordinate ?? this.coordinate,
      immagineUrl: immagineUrl,
      itinerario: itinerario,
    );
  }
}












