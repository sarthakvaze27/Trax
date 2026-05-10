// Explore Screen - Explore sports facilities
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';
import '../../services/api_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _tournaments = [];
  List<dynamic> _facilities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final t = await ApiService.getTournaments();
      final f = await ApiService.getFacilities();
      setState(() {
        _tournaments = t;
        _facilities = f;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Explore',
            style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: AppColors.green,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.report_outlined, color: Colors.white),
            tooltip: 'Submit Grievance',
            onPressed: _showGrievanceSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Tournaments'),
            Tab(text: 'All Facilities'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.green,
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildTournamentsTab(),
                  _buildFacilitiesTab(),
                ],
              ),
            ),
    );
  }

  // ── TOURNAMENTS ───────────────────────────────────────────────────────────
  Widget _buildTournamentsTab() {
    if (_tournaments.isEmpty) {
      return _emptyState('No tournaments scheduled',
          'Check back soon for upcoming events', Icons.emoji_events_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tournaments.length,
      itemBuilder: (_, i) => _tournamentCard(_tournaments[i]),
    );
  }

  Widget _tournamentCard(Map<String, dynamic> t) {
    final statusColor = t['status'] == 'upcoming'
        ? AppColors.blue
        : t['status'] == 'ongoing'
            ? AppColors.green
            : AppColors.textMuted;
    final statusBg = t['status'] == 'upcoming'
        ? AppColors.blueLight
        : t['status'] == 'ongoing'
            ? AppColors.green50
            : AppColors.surface;

    final int max = (t['max_teams'] as int?) ?? 1;
    final int reg = (t['registered'] as int?) ?? 0;
    final double fill = max > 0 ? reg / max : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(t['name'] ?? '',
                      style: GoogleFonts.syne(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text((t['status'] as String).toUpperCase(),
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              _pill('⚽ ${t['sport']}', AppColors.green50, AppColors.green),
              const SizedBox(width: 6),
              if (t['prize_pool'] != null)
                _pill('🏆 ${t['prize_pool']}', AppColors.accentLight,
                    const Color(0xFFB8780A)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.calendar_month_outlined,
                  size: 13, color: AppColors.textSecond),
              const SizedBox(width: 5),
              Text('${t['start_date']} → ${t['end_date']}',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textSecond)),
            ]),
            const SizedBox(height: 10),
            // Registration progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Teams: $reg / $max',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecond)),
                Text('${(fill * 100).toStringAsFixed(0)}% full',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fill.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.green),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    await ApiService.registerTournament(t['id']);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tournament registration successful!'),
                          backgroundColor: AppColors.green,
                        ),
                      );
                      _load();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.green),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Register Interest',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FACILITIES MAP-STYLE LIST ─────────────────────────────────────────────
  Widget _buildFacilitiesTab() {
    return Column(
      children: [
        // Map placeholder banner
        Container(
          width: double.infinity,
          height: 140,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.green, AppColors.greenDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Dots representing facility locations
              ...[
                const Offset(0.2, 0.3),
                const Offset(0.5, 0.6),
                const Offset(0.7, 0.4),
                const Offset(0.35, 0.7),
                const Offset(0.8, 0.7),
              ].map((pos) => Positioned(
                    left: pos.dx * 300,
                    top: pos.dy * 100,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.accent, width: 2),
                      ),
                    ),
                  )),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_outlined,
                        color: Colors.white70, size: 28),
                    const SizedBox(height: 6),
                    Text('${_facilities.length} Facilities Across Goa',
                        style: GoogleFonts.syne(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text('Panaji · Margao · Vasco · Mapusa',
                        style: GoogleFonts.dmSans(
                            color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _facilities.length,
            itemBuilder: (_, i) => _facilityListItem(_facilities[i]),
          ),
        ),
      ],
    );
  }

  Widget _facilityListItem(Map<String, dynamic> f) {
    final sports = (f['sports'] as List<dynamic>?) ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.green50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
              child: Text(f['emoji'] ?? '🏟️',
                  style: const TextStyle(fontSize: 22))),
        ),
        title: Text(f['name'] ?? '',
            style: GoogleFonts.syne(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.location_on, size: 11, color: AppColors.textSecond),
              const SizedBox(width: 3),
              Text('${f['location']} · ${f['distance_km']} km',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textSecond)),
            ]),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: sports
                  .take(3)
                  .map((s) => _pill(s.toString(), AppColors.green50, AppColors.green))
                  .toList(),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${f['price_per_hr']}',
                style: GoogleFonts.syne(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green)),
            Text('/hr',
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  // ── GRIEVANCE SHEET ───────────────────────────────────────────────────────
  void _showGrievanceSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'medium';
    String? selectedFacilityId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Submit Grievance',
                    style: GoogleFonts.syne(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                Text('Report a facility issue to SAG administration',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 20),
                _inputField(titleCtrl, 'Issue Title', Icons.title),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Describe the issue...',
                      hintStyle: GoogleFonts.dmSans(
                          fontSize: 14, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Priority selector
                Text('Priority',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecond)),
                const SizedBox(height: 8),
                Row(children: [
                  for (final p in ['low', 'medium', 'high'])
                    GestureDetector(
                      onTap: () => setSheetState(() => priority = p),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: priority == p
                              ? (p == 'high'
                                  ? AppColors.red
                                  : p == 'medium'
                                      ? AppColors.accent
                                      : AppColors.green)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: priority == p
                                ? Colors.transparent
                                : AppColors.border,
                          ),
                        ),
                        child: Text(p.toUpperCase(),
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: priority == p
                                    ? Colors.white
                                    : AppColors.textSecond)),
                      ),
                    ),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      try {
                        await ApiService.submitGrievance(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          facilityId: selectedFacilityId,
                          priority: priority,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Grievance submitted to SAG!'),
                              backgroundColor: AppColors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Submit Grievance',
                        style: GoogleFonts.syne(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon:
              Icon(icon, color: AppColors.textMuted, size: 20),
          hintText: hint,
          hintStyle:
              GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _emptyState(String title, String sub, IconData icon) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 56, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(title,
            style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(sub,
            style:
                GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted)),
      ]),
    );
  }
}
