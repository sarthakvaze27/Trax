// Admin Facilities Screen - Manage facilities
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';
import '../../services/api_service.dart';

class AdminFacilitiesScreen extends StatefulWidget {
  const AdminFacilitiesScreen({super.key});

  @override
  State<AdminFacilitiesScreen> createState() =>
      _AdminFacilitiesScreenState();
}

class _AdminFacilitiesScreenState extends State<AdminFacilitiesScreen> {
  List<dynamic> _facilities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final f = await ApiService.getFacilities();
      setState(() {
        _facilities = f;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleOpen(Map<String, dynamic> f) async {
    final newVal = !(f['is_open'] as bool? ?? true);
    try {
      await ApiService.updateFacility(f['id'], {'is_open': newVal});
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showEditPrice(Map<String, dynamic> f) {
    final priceCtrl =
        TextEditingController(text: '${f['price_per_hr']}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Price',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f['name'] ?? '',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecond)),
            const SizedBox(height: 14),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price per hour (₹)',
                labelStyle:
                    GoogleFonts.inter(color: AppColors.textSecond),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecond)),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = int.tryParse(priceCtrl.text);
              if (price == null) return;
              try {
                await ApiService.updateFacility(
                    f['id'], {'price_per_hr': price});
                if (mounted) Navigator.pop(context);
                _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Price updated!'),
                        backgroundColor: AppColors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green),
            child: Text('Save',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Facilities',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: AppColors.sidebar,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _facilities.length,
                itemBuilder: (_, i) => _facilityCard(_facilities[i]),
              ),
            ),
    );
  }

  Widget _facilityCard(Map<String, dynamic> f) {
    final isOpen = f['is_open'] as bool? ?? true;
    final util = (f['utilization'] as int?) ?? 0;
    final sports = (f['sports'] as List<dynamic>?) ?? [];
    final amenities = (f['amenities'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)
        ],
      ),
      child: Column(
        children: [
          // Facility header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOpen
                    ? [AppColors.green, AppColors.greenDark]
                    : [Colors.grey.shade600, Colors.grey.shade800],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(f['emoji'] ?? '🏟️',
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f['name'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text('${f['location']} · ${f['sag_tag'] ?? ''}',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.white60)),
                    ],
                  ),
                ),
                Switch(
                  value: isOpen,
                  onChanged: (_) => _toggleOpen(f),
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white38,
                  inactiveThumbColor: Colors.white54,
                  inactiveTrackColor: Colors.white12,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Stats row
                Row(
                  children: [
                    _stat('₹${f['price_per_hr']}/hr', 'Price',
                        AppColors.green),
                    const SizedBox(width: 8),
                    _stat('${f['rating']} ★', 'Rating', AppColors.accent),
                    const SizedBox(width: 8),
                    _stat('$util%', 'Utilization', util > 80
                        ? AppColors.red
                        : AppColors.blue),
                  ],
                ),
                const SizedBox(height: 10),
                // Utilization bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: util / 100,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      util > 80
                          ? AppColors.red
                          : util > 60
                              ? AppColors.accent
                              : AppColors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Sports tags
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sports
                        .map((s) => _tag(s.toString(), AppColors.green50,
                            AppColors.green))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                // Amenities
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: amenities
                        .take(4)
                        .map((a) => _tag(a.toString(), AppColors.surface,
                            AppColors.textSecond))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditPrice(f),
                        icon: const Icon(Icons.edit, size: 14),
                        label: Text('Edit Price',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleOpen(f),
                        icon: Icon(
                            isOpen ? Icons.close : Icons.check, size: 14),
                        label: Text(isOpen ? 'Close Facility' : 'Open Facility',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isOpen ? AppColors.red : AppColors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}
