import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import 'admin_shell.dart'; // for AdminTheme

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    wsService.addUpdateListener(_onWsEvent);
    _load();
  }

  @override
  void dispose() {
    wsService.removeUpdateListener(_onWsEvent);
    _animCtrl.dispose();
    super.dispose();
  }

  void _onWsEvent(String event, Map<String, dynamic> data) {
    if (event == 'booking_created' ||
        event == 'booking_cancelled' ||
        event == 'grievance_created' ||
        event == 'grievance_updated') {
      _load(showLoading: false);
    }
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final d = await ApiService.getAdminDashboard();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _fmt(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final kpis = _data?['kpis'] as Map<String, dynamic>? ?? {};
    final facilities = (_data?['facilities'] as List<dynamic>?) ?? [];
    final recentBookings = (_data?['recent_bookings'] as List<dynamic>?) ?? [];
    final analytics = _data?['analytics'] as Map<String, dynamic>? ?? {};
    final dailyBookings = (analytics['daily_bookings'] as List<dynamic>?) ?? [];
    final topFacilities = (analytics['top_facilities'] as List<dynamic>?) ?? [];
    final peakSlots = (analytics['peak_slots'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AdminTheme.brand,
        backgroundColor: AdminTheme.surface,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_loading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          color: AdminTheme.brand,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Loading dashboard…',
                          style: GoogleFonts.sora(
                              fontSize: 13, color: AdminTheme.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── KPI Grid ───────────────────────────────────────
                      _sectionLabel('PERFORMANCE OVERVIEW'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(children: [
                              Expanded(
                                child: _kpiCard(
                                  value: '₹${_fmt(kpis['total_revenue'])}',
                                  label: 'Total Revenue',
                                  icon: Icons.currency_rupee_rounded,
                                  iconColor: AdminTheme.green,
                                  iconBg: AdminTheme.greenBg,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _kpiCard(
                                  value: '${kpis['total_bookings'] ?? 0}',
                                  label: 'Total Bookings',
                                  icon: Icons.confirmation_num_outlined,
                                  iconColor: AdminTheme.blue,
                                  iconBg: AdminTheme.blueBg,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                child: _kpiCard(
                                  value: '${kpis['total_users'] ?? 0}',
                                  label: 'Active Users',
                                  icon: Icons.people_alt_outlined,
                                  iconColor: AdminTheme.purple,
                                  iconBg: AdminTheme.purpleBg,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _kpiCard(
                                  value: '${kpis['open_grievances'] ?? 0}',
                                  label: 'Open Grievances',
                                  icon: Icons.warning_amber_rounded,
                                  iconColor: AdminTheme.orange,
                                  iconBg: AdminTheme.orangeBg,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                child: _kpiCard(
                                  value: '${kpis['today_bookings'] ?? 0}',
                                  label: 'Today Bookings',
                                  icon: Icons.today_outlined,
                                  iconColor: AdminTheme.blue,
                                  iconBg: AdminTheme.blueBg,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _kpiCard(
                                  value: '${kpis['cancelled_bookings'] ?? 0}',
                                  label: 'Cancelled',
                                  icon: Icons.event_busy_outlined,
                                  iconColor: AdminTheme.red,
                                  iconBg: AdminTheme.redBg,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Facility Utilization ───────────────────────────
                      if (dailyBookings.isNotEmpty ||
                          topFacilities.isNotEmpty ||
                          peakSlots.isNotEmpty) ...[
                        _sectionLabel('BOOKING ANALYTICS'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              if (dailyBookings.isNotEmpty)
                                _analyticsCard(
                                  title: 'Last 7 booking days',
                                  icon: Icons.insights_rounded,
                                  child: Column(
                                    children: dailyBookings
                                        .map((d) => _metricBar(
                                              label: d['date'] as String? ?? '',
                                              value: (d['bookings'] as num?)
                                                      ?.toInt() ??
                                                  0,
                                              maxValue: _maxMetric(
                                                  dailyBookings, 'bookings'),
                                              trailing:
                                                  'Rs ${_fmt(d['revenue'])}',
                                              color: AdminTheme.brand,
                                            ))
                                        .toList(),
                                  ),
                                ),
                              if (topFacilities.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _analyticsCard(
                                  title: 'Top facilities',
                                  icon: Icons.leaderboard_outlined,
                                  child: Column(
                                    children: topFacilities
                                        .map((f) => _rankRow(
                                              f['facility'] as String? ??
                                                  'Unknown',
                                              '${f['bookings'] ?? 0} bookings',
                                              'Rs ${_fmt(f['revenue'])}',
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                              if (peakSlots.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _analyticsCard(
                                  title: 'Peak slot demand',
                                  icon: Icons.schedule_rounded,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: peakSlots
                                        .map((s) => _slotChip(
                                              s['slot'] as String? ?? '',
                                              '${s['bookings'] ?? 0}',
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      _sectionLabel('FACILITY UTILIZATION'),
                      ...facilities.map((f) => _facilityRow(f)),

                      const SizedBox(height: 28),

                      // ── Recent Bookings ────────────────────────────────
                      if (recentBookings.isNotEmpty) ...[
                        _sectionLabel('RECENT BOOKINGS'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AdminTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AdminTheme.border),
                            ),
                            child: Column(
                              children: recentBookings.asMap().entries.map((e) {
                                final b = e.value as Map<String, dynamic>;
                                final isLast =
                                    e.key == recentBookings.length - 1;
                                return _recentBookingRow(b, isLast: isLast);
                              }).toList(),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      color: AdminTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: GoogleFonts.sora(
                            fontSize: 13,
                            color: AdminTheme.textSecondary,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('Dashboard',
                        style: GoogleFonts.sora(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.textPrimary,
                            letterSpacing: -0.5)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AdminTheme.greenBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AdminTheme.brand.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AdminTheme.brand, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('LIVE',
                        style: GoogleFonts.sora(
                            fontSize: 10,
                            color: AdminTheme.brand,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AdminTheme.border, height: 1),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(label,
          style: GoogleFonts.sora(
              fontSize: 10,
              color: AdminTheme.textMuted,
              letterSpacing: 2,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _kpiCard({
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.textPrimary,
                  letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.sora(
                  fontSize: 11,
                  color: AdminTheme.textSecondary,
                  fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  int _maxMetric(List<dynamic> items, String key) {
    var max = 1;
    for (final item in items) {
      final map = item as Map<String, dynamic>;
      final value = (map[key] as num?)?.toInt() ?? 0;
      if (value > max) max = value;
    }
    return max;
  }

  Widget _analyticsCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AdminTheme.brand),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.sora(
                      fontSize: 13,
                      color: AdminTheme.textPrimary,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _metricBar({
    required String label,
    required int value,
    required int maxValue,
    required String trailing,
    required Color color,
  }) {
    final pct = maxValue == 0 ? 0.0 : value / maxValue;
    final progress = pct.clamp(0.04, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: GoogleFonts.sora(
                        fontSize: 11,
                        color: AdminTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
              ),
              Text('$value bookings  |  $trailing',
                  style: GoogleFonts.sora(
                      fontSize: 11,
                      color: AdminTheme.textPrimary,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AdminTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankRow(String title, String subtitle, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                        fontSize: 12,
                        color: AdminTheme.textPrimary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.sora(
                        fontSize: 10, color: AdminTheme.textSecondary)),
              ],
            ),
          ),
          Text(value,
              style: GoogleFonts.sora(
                  fontSize: 12,
                  color: AdminTheme.textPrimary,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _slotChip(String slot, String bookings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AdminTheme.blueBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AdminTheme.blue.withValues(alpha: 0.16)),
      ),
      child: Text('$slot  |  $bookings bookings',
          style: GoogleFonts.sora(
              fontSize: 11,
              color: AdminTheme.blue,
              fontWeight: FontWeight.w700)),
    );
  }

  String _bookedBy(Map<String, dynamic> booking) {
    final user = booking['booked_by'];
    if (user is Map<String, dynamic>) {
      final name = user['name'] as String?;
      if (name != null && name.trim().isNotEmpty) return name;
    }
    return 'Unknown user';
  }

  Widget _facilityRow(Map<String, dynamic> f) {
    final util = (f['utilization'] as int?) ?? 0;
    final isOpen = f['is_open'] as bool? ?? true;
    final Color barColor = util > 80
        ? AdminTheme.red
        : util > 60
            ? AdminTheme.orange
            : AdminTheme.brand;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AdminTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminTheme.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(f['emoji'] ?? '🏟️', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(f['name'] ?? '',
                      style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.textPrimary)),
                ),
                if (!isOpen)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AdminTheme.redBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('CLOSED',
                        style: GoogleFonts.sora(
                            fontSize: 8,
                            color: AdminTheme.red,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                  ),
                const SizedBox(width: 10),
                Text('$util%',
                    style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: barColor)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: util / 100,
                minHeight: 5,
                backgroundColor: AdminTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentBookingRow(Map<String, dynamic> b, {required bool isLast}) {
    final status = b['status'] as String? ?? '';
    final statusColor =
        status == 'confirmed' ? AdminTheme.green : AdminTheme.textMuted;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b['facility'] as String? ?? 'Unknown',
                        style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AdminTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Booked by ${_bookedBy(b)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sora(
                            fontSize: 11, color: AdminTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${b['date']}  |  ${b['time_label']}',
                        style: GoogleFonts.sora(
                            fontSize: 11, color: AdminTheme.textSecondary)),
                  ],
                ),
              ),
              Text(
                '₹${b['total_amount']}',
                style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.textPrimary),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
              height: 0, color: AdminTheme.border, indent: 36, endIndent: 16),
      ],
    );
  }
}
