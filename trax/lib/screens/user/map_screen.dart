// Map Screen - Map view of sports facilities
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app_colors.dart';
import '../../providers/facility_provider.dart';
import '../booking/booking_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selected;

  static const LatLng _goaCenter = LatLng(15.4909, 73.8278);

  @override
  Widget build(BuildContext context) {
    final facilityProv = Provider.of<FacilityProvider>(context);
    final facilities = facilityProv.facilities;

    final markers = facilities.map((f) {
      final lat = (f['lat'] as num?)?.toDouble() ?? 15.4909;
      final lng = (f['lng'] as num?)?.toDouble() ?? 73.8278;
      final isOpen = f['is_open'] as bool? ?? true;
      final isSelected = _selected?['id'] == f['id'];

      return Marker(
        point: LatLng(lat, lng),
        width: isSelected ? 52 : 44,
        height: isSelected ? 52 : 44,
        child: GestureDetector(
          onTap: () => setState(() => _selected = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isOpen ? AppColors.green : Colors.grey.shade500,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.accent : Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isOpen
                      ? AppColors.green.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.3),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                f['emoji'] ?? '🏟️',
                style: TextStyle(fontSize: isSelected ? 22 : 18),
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _goaCenter,
              initialZoom: 10.5,
              minZoom: 8,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trax.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.green, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Facility Map',
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text('${facilities.length} SAG facilities across Goa',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _mapController.move(_goaCenter, 10.5);
                      setState(() => _selected = null);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.my_location,
                          color: AppColors.green, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: 12,
            top: 130,
            child: Column(
              children: [
                _legendItem(AppColors.green, 'Open'),
                const SizedBox(height: 6),
                _legendItem(Colors.grey, 'Closed'),
              ],
            ),
          ),

          if (_selected != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _facilityCard(context, _selected!),
            )
          else
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Tap a marker to view facility',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _facilityCard(BuildContext context, Map<String, dynamic> f) {
    final isOpen = f['is_open'] as bool? ?? true;
    final sports = (f['sports'] as List<dynamic>?) ?? [];

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isOpen ? AppColors.green : AppColors.border,
              width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(f['emoji'] ?? '🏟️',
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f['name'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(f['location'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecond)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: sports.take(2).map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.green50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(s.toString(),
                                style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: AppColors.green,
                                    fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selected = null),
                  child: const Icon(Icons.close,
                      color: AppColors.textMuted, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${f['price_per_hr']}/hr',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.green)),
                    Text('⭐ ${f['rating']} · ${f['distance_km']} km',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted)),
                  ],
                ),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? AppColors.green50
                          : AppColors.redLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(isOpen ? '● OPEN' : '● CLOSED',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isOpen
                                ? AppColors.green
                                : AppColors.red)),
                  ),
                  if (isOpen) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(facility: f),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Book',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
