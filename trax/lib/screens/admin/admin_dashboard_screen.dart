// Admin Dashboard Screen - Main admin dashboard
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await ApiService.getAdminDashboard();
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kpis = _data?['kpis'] as Map<String, dynamic>? ?? {};
    final facilities =
        (_data?['facilities'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accent,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sidebar, AppColors.dark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SAG Admin Portal',
                                style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            Text('Sports Authority of Goa',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.white38)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.admin_panel_settings,
                                color: AppColors.accent, size: 14),
                            const SizedBox(width: 5),
                            Text('Admin',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // KPI Cards
            if (_loading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overview',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecond,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _kpiCard(
                            '₹${_fmt(kpis['total_revenue'] ?? 0)}',
                            'Total Revenue',
                            Icons.currency_rupee,
                            AppColors.green,
                            AppColors.green50,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _kpiCard(
                            '${kpis['total_bookings'] ?? 0}',
                            'Total Bookings',
                            Icons.book_online,
                            AppColors.blue,
                            AppColors.blueLight,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: _kpiCard(
                            '${kpis['total_users'] ?? 0}',
                            'Registered Users',
                            Icons.people_outline,
                            AppColors.purple,
                            AppColors.purpleLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _kpiCard(
                            '${kpis['open_grievances'] ?? 0}',
                            'Open Grievances',
                            Icons.report_outlined,
                            AppColors.red,
                            AppColors.redLight,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              // Facilities utilization
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text('Facility Utilization',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecond,
                          letterSpacing: 0.5)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: _facilityUtilCard(facilities[i]),
                  ),
                  childCount: facilities.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(
      String value, String label, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _facilityUtilCard(Map<String, dynamic> f) {
    final util = (f['utilization'] as int?) ?? 0;
    final Color barColor = util > 80
        ? AppColors.red
        : util > 60
            ? AppColors.accent
            : AppColors.green;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(f['emoji'] ?? '🏟️',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(f['name'] ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ]),
              Text('$util%',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: barColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: util / 100,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
