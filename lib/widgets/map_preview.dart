import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPreview extends StatelessWidget {
  final double? lat;
  final double? lng;
  const MapPreview({super.key, this.lat, this.lng});

  @override
  Widget build(BuildContext context) {
    if (lat == null || lng == null) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No location selected'),
      );
    }
    final pos = LatLng(lat!, lng!);
    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: pos, zoom: 15),
          markers: {Marker(markerId: const MarkerId('loc'), position: pos)},
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          liteModeEnabled: true,
        ),
      ),
    );
  }
}

