import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../services/api_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _bookings = [];
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
      final b = await ApiService.getMyBookings();
      setState(() {
        _bookings = b;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancel(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Booking',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to cancel? A simulated refund will be initiated.',
            style: GoogleFonts.dmSans(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No',
                  style: GoogleFonts.dmSans(color: AppColors.textSecond))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              child: Text('Cancel Booking',
                  style: GoogleFonts.dmSans(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.cancelBooking(bookingId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Booking cancelled. Refund initiated.'),
              backgroundColor: AppColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming =
        _bookings.where((b) => b['status'] == 'confirmed').toList();
    final past = _bookings
        .where((b) => b['status'] != 'confirmed')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('My Bookings',
            style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: AppColors.green,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Past (${past.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.green))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.green,
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildList(upcoming, canCancel: true),
                  _buildList(past, canCancel: false),
                ],
              ),
            ),
    );
  }

  Widget _buildList(List<dynamic> bookings, {required bool canCancel}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No bookings yet',
                style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Book a facility from the Home tab',
                style:
                    GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _bookingCard(bookings[i], canCancel: canCancel),
    );
  }

  Widget _bookingCard(Map<String, dynamic> b, {required bool canCancel}) {
    final statusColor = b['status'] == 'confirmed'
        ? AppColors.green
        : b['status'] == 'cancelled'
            ? AppColors.red
            : AppColors.textMuted;
    final statusBg = b['status'] == 'confirmed'
        ? AppColors.green50
        : b['status'] == 'cancelled'
            ? AppColors.redLight
            : AppColors.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    b['facilities']?['name'] ?? 'Facility',
                    style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (b['status'] as String).toUpperCase(),
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.textSecond),
              const SizedBox(width: 4),
              Text(b['facilities']?['location'] ?? '',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textSecond)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textSecond),
              const SizedBox(width: 4),
              Text('${b['date']}  ·  ${b['time_label']}',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textSecond)),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // QR code snippet
                if (b['qr_code'] != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      const Icon(Icons.qr_code_2,
                          size: 14, color: AppColors.textSecond),
                      const SizedBox(width: 4),
                      Text(b['qr_code'],
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecond,
                              letterSpacing: 1)),
                    ]),
                  ),
                ],
                Row(children: [
                  Text('₹${b['total_amount']}',
                      style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green)),
                  if (canCancel) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _cancel(b['id']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Cancel',
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.red)),
                      ),
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
}
