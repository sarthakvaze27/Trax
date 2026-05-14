import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import 'admin_shell.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    wsService.addUpdateListener(_onWsEvent);
    _load();
  }

  @override
  void dispose() {
    wsService.removeUpdateListener(_onWsEvent);
    super.dispose();
  }

  void _onWsEvent(String event, Map<String, dynamic> data) {
    if (event == 'booking_created' || event == 'booking_cancelled') {
      _load(showLoading: false);
    }
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final data = await ApiService.getAdminBookings();
      if (!mounted) return;
      setState(() {
        _bookings = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _visibleBookings {
    if (_filter == 'all') return _bookings;
    return _bookings.where((b) => b['status'] == _filter).toList();
  }

  String _customerName(Map<String, dynamic> booking) {
    final user = booking['user'];
    if (user is Map<String, dynamic>) {
      final name = user['name'] as String?;
      if (name != null && name.trim().isNotEmpty) return name;
    }
    return 'Unknown user';
  }

  String _customerMeta(Map<String, dynamic> booking) {
    final user = booking['user'];
    if (user is Map<String, dynamic>) {
      final email = user['email'] as String? ?? '';
      final phone = user['phone'] as String? ?? '';
      if (phone.isNotEmpty) return phone;
      if (email.isNotEmpty) return email;
    }
    return 'No contact saved';
  }

  String _facilityName(Map<String, dynamic> booking) {
    final facility = booking['facilities'];
    if (facility is Map<String, dynamic>) {
      return facility['name'] as String? ?? 'Unknown facility';
    }
    return 'Unknown facility';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AdminTheme.green;
      case 'cancelled':
        return AdminTheme.red;
      default:
        return AdminTheme.textMuted;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'confirmed':
        return AdminTheme.greenBg;
      case 'cancelled':
        return AdminTheme.redBg;
      default:
        return AdminTheme.bg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleBookings;

    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AdminTheme.brand,
        backgroundColor: AdminTheme.surface,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _filters()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AdminTheme.brand,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (visible.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No bookings found',
                    style: GoogleFonts.sora(
                      color: AdminTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    return _bookingCard(
                      visible[index] as Map<String, dynamic>,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      color: AdminTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookings',
            style: GoogleFonts.sora(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track every slot reservation and customer detail',
            style: GoogleFonts.sora(
              fontSize: 12,
              color: AdminTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AdminTheme.border, height: 1),
        ],
      ),
    );
  }

  Widget _filters() {
    const filters = [
      ('all', 'All'),
      ('confirmed', 'Confirmed'),
      ('cancelled', 'Cancelled'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: filters.map((item) {
          final selected = _filter == item.$1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => setState(() => _filter = item.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        selected ? AdminTheme.brandLight : AdminTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AdminTheme.brand : AdminTheme.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.$2,
                      style: GoogleFonts.sora(
                        color: selected
                            ? AdminTheme.brand
                            : AdminTheme.textSecondary,
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String? ?? '';
    final amount = booking['total_amount'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdminTheme.blueBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AdminTheme.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customerName(booking),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        color: AdminTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _customerMeta(booking),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.sora(
                    color: _statusColor(status),
                    fontSize: 9,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AdminTheme.border, height: 1),
          const SizedBox(height: 12),
          _detailRow(
            Icons.stadium_outlined,
            _facilityName(booking),
            'Rs $amount',
          ),
          const SizedBox(height: 8),
          _detailRow(
            Icons.schedule_rounded,
            '${booking['date'] ?? ''}',
            '${booking['time_label'] ?? ''}',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AdminTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sora(
              color: AdminTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: GoogleFonts.sora(
            color: AdminTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
