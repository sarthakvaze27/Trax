import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'admin_shell.dart';

class AdminFacilitiesScreen extends StatefulWidget {
  const AdminFacilitiesScreen({super.key});

  @override
  State<AdminFacilitiesScreen> createState() => _AdminFacilitiesScreenState();
}

class _AdminFacilitiesScreenState extends State<AdminFacilitiesScreen> {
  List<dynamic> _facilities = [];
  bool _loading = true;
  String _search = '';

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
      if (mounted) _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.sora(fontSize: 13, color: Colors.white)),
        backgroundColor: AdminTheme.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.sora(fontSize: 13, color: Colors.white)),
        backgroundColor: AdminTheme.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showEditPrice(Map<String, dynamic> f) {
    final priceCtrl = TextEditingController(text: '${f['price_per_hr']}');

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AdminTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Update Price',
                    style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(f['name'] ?? '',
                    style: GoogleFonts.sora(
                        fontSize: 13, color: AdminTheme.textSecondary)),
                const SizedBox(height: 22),
                _lightInput(
                  controller: priceCtrl,
                  hint: 'Price per hour',
                  prefix: '₹ ',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _outlineBtn('Cancel',
                          onTap: () => Navigator.pop(context)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _solidBtn('Save Changes', onTap: () async {
                        final price = int.tryParse(priceCtrl.text);
                        if (price == null) return;
                        try {
                          await ApiService.updateFacility(
                              f['id'], {'price_per_hr': price});
                          if (mounted) {
                            Navigator.pop(context);
                            _load();
                            _showSuccess('Price updated successfully');
                          }
                        } catch (e) {
                          if (mounted) _showError(e.toString());
                        }
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _facilities;
    return _facilities.where((f) {
      final name = (f['name'] as String? ?? '').toLowerCase();
      final loc = (f['location'] as String? ?? '').toLowerCase();
      return name.contains(_search.toLowerCase()) ||
          loc.contains(_search.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AdminTheme.brand, strokeWidth: 2.5))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AdminTheme.brand,
                    backgroundColor: AdminTheme.surface,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _facilityCard(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AdminTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Facilities',
              style: GoogleFonts.sora(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.textPrimary,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('${_facilities.length} facilities across Goa',
              style: GoogleFonts.sora(
                  fontSize: 12, color: AdminTheme.textSecondary)),
          const SizedBox(height: 16),
          _searchBar(),
          const SizedBox(height: 4),
          const Divider(color: AdminTheme.border, height: 1),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: GoogleFonts.sora(fontSize: 14, color: AdminTheme.textPrimary),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded,
              color: AdminTheme.textMuted, size: 18),
          hintText: 'Search facilities…',
          hintStyle:
              GoogleFonts.sora(fontSize: 14, color: AdminTheme.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _facilityCard(Map<String, dynamic> f) {
    final isOpen = f['is_open'] as bool? ?? true;
    final util = (f['utilization'] as int?) ?? 0;
    final sports = (f['sports'] as List<dynamic>?) ?? [];
    final amenities = (f['amenities'] as List<dynamic>?) ?? [];

    final Color utilColor = util > 80
        ? AdminTheme.red
        : util > 60
            ? AdminTheme.orange
            : AdminTheme.brand;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AdminTheme.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: Center(
                    child: Text(f['emoji'] ?? '🏟️',
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f['name'] ?? '',
                          style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AdminTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: AdminTheme.textMuted),
                        const SizedBox(width: 3),
                        Text(f['location'] ?? '',
                            style: GoogleFonts.sora(
                                fontSize: 11, color: AdminTheme.textSecondary)),
                      ]),
                    ],
                  ),
                ),
                // Open/Closed badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen ? AdminTheme.greenBg : AdminTheme.redBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isOpen ? AdminTheme.brand : AdminTheme.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(isOpen ? 'Open' : 'Closed',
                          style: GoogleFonts.sora(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color:
                                  isOpen ? AdminTheme.brand : AdminTheme.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Stats Row ────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AdminTheme.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminTheme.border),
            ),
            child: Row(
              children: [
                _statCol('₹${f['price_per_hr']}/hr', 'Price'),
                _dividerV(),
                _statCol('${f['rating']} ★', 'Rating'),
                _dividerV(),
                _statCol('$util%', 'Utilization', color: utilColor),
              ],
            ),
          ),

          // ── Utilization bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: util / 100,
                minHeight: 5,
                backgroundColor: AdminTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(utilColor),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Sport Tags ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: sports
                  .take(4)
                  .map((s) =>
                      _tag(s.toString(), AdminTheme.greenBg, AdminTheme.brand))
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // ── Amenity Tags ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: amenities
                  .take(4)
                  .map((a) => _tag(
                      a.toString(), AdminTheme.bg, AdminTheme.textSecondary))
                  .toList(),
            ),
          ),

          const SizedBox(height: 14),

          // ── Actions ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Row(children: [
              Expanded(
                child: _outlineBtn(
                  'Edit Price',
                  icon: Icons.edit_outlined,
                  onTap: () => _showEditPrice(f),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _solidBtn(
                  isOpen ? 'Close Facility' : 'Open Facility',
                  icon: isOpen ? Icons.lock_outline : Icons.lock_open_outlined,
                  danger: isOpen,
                  onTap: () => _toggleOpen(f),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statCol(String value, String label, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color ?? AdminTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.sora(
                  fontSize: 9,
                  color: AdminTheme.textMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _dividerV() {
    return Container(width: 1, height: 28, color: AdminTheme.border);
  }

  Widget _tag(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AdminTheme.border)),
      child: Text(label,
          style: GoogleFonts.sora(
              fontSize: 10, fontWeight: FontWeight.w500, color: fg)),
    );
  }

  Widget _outlineBtn(String label,
      {IconData? icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdminTheme.borderMid),
          color: AdminTheme.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AdminTheme.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _solidBtn(String label,
      {IconData? icon, bool danger = false, required VoidCallback onTap}) {
    final bg = danger ? AdminTheme.redBg : AdminTheme.greenBg;
    final fg = danger ? AdminTheme.red : AdminTheme.brand;
    final border = danger
        ? AdminTheme.red.withValues(alpha: 0.3)
        : AdminTheme.brand.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: GoogleFonts.sora(
                    fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _lightInput({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.borderMid),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.sora(fontSize: 15, color: AdminTheme.textPrimary),
        decoration: InputDecoration(
          prefixText: prefix,
          prefixStyle:
              GoogleFonts.sora(fontSize: 15, color: AdminTheme.textSecondary),
          hintText: hint,
          hintStyle:
              GoogleFonts.sora(fontSize: 15, color: AdminTheme.textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
