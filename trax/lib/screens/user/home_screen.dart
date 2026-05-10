// Home Screen - User home screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/facility_provider.dart';
import '../booking/booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _sportFilter = 'All';
  final _sports = ['All', 'Football', 'Cricket', 'Badminton', 'Swimming', 'Basketball'];
  final _sportEmojis = {
    'All': '🏟️', 'Football': '⚽', 'Cricket': '🏏',
    'Badminton': '🏸', 'Swimming': '🏊', 'Basketball': '🏀',
  };

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final facilityProv = Provider.of<FacilityProvider>(context);
    final facilities = facilityProv.facilities;

    final filtered = _sportFilter == 'All'
        ? facilities
        : facilities
            .where((f) =>
                (f['sports'] as List<dynamic>? ?? []).contains(_sportFilter))
            .toList();

    final openCount = facilities.where((f) => f['is_open'] == true).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Hero banner ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.green, AppColors.greenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text('Good day,',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: Colors.white60)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${auth.userName ?? 'Athlete'} 👋',
                          style: GoogleFonts.syne(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          const Icon(Icons.stars_rounded,
                              color: Color(0xFFF5A623), size: 14),
                          const SizedBox(width: 4),
                          Text('${auth.user?['loyalty_points'] ?? 0} pts',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.search,
                          color: Colors.white60, size: 18),
                      const SizedBox(width: 8),
                      Text('Find facilities in Goa...',
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: Colors.white54)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(children: [
                    _heroStat('${facilities.length}', 'Facilities'),
                    _divider(),
                    _heroStat('$openCount', 'Open Now'),
                    _divider(),
                    _heroStat('5', 'Districts'),
                  ]),
                ],
              ),
            ),
          ),

          // ── Sport filter chips ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: _sports.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = _sports[i];
                  final active = _sportFilter == s;
                  return GestureDetector(
                    onTap: () => setState(() => _sportFilter = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? AppColors.green : AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: active
                                ? AppColors.green
                                : AppColors.border),
                      ),
                      child: Text(
                        '${_sportEmojis[s]} $s',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? Colors.white
                              : AppColors.textSecond,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Section header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nearby Facilities',
                      style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text('${filtered.length} found',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),

          // ── Facility cards ───────────────────────────────────────────────
          facilityProv.loading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppColors.green),
                    ),
                  ),
                )
              : filtered.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(children: [
                            const Icon(Icons.search_off,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No facilities found',
                                style: GoogleFonts.syne(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _facilityCard(context, filtered[i]),
                          childCount: filtered.length,
                        ),
                      ),
                    ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _facilityCard(BuildContext context, Map<String, dynamic> f) {
    final isOpen = f['is_open'] as bool? ?? true;
    final sports = (f['sports'] as List<dynamic>?) ?? [];
    final util = (f['utilization'] as int?) ?? 0;

    return GestureDetector(
      onTap: isOpen
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingScreen(facility: f),
                ),
              )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 14)
          ],
        ),
        child: Column(
          children: [
            // ── Card header with gradient ─────────────────────────────
            Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOpen
                      ? [
                          AppColors.green.withValues(alpha: 0.8),
                          AppColors.greenDark
                        ]
                      : [Colors.grey.shade400, Colors.grey.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  // Emoji
                  Center(
                    child: Text(f['emoji'] ?? '🏟️',
                        style: const TextStyle(fontSize: 52)),
                  ),
                  // SAG tag
                  Positioned(
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(f['sag_tag'] ?? '',
                          style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF22C55E)
                            : AppColors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(isOpen ? 'OPEN' : 'CLOSED',
                          style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Card body ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(f['name'] ?? '',
                            style: GoogleFonts.syne(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ),
                      Text('⭐ ${f['rating']}',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on,
                        size: 12, color: AppColors.textSecond),
                    const SizedBox(width: 3),
                    Text(
                        '${f['location']} · ${f['distance_km']} km away',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textSecond)),
                  ]),
                  const SizedBox(height: 8),
                  // Sports chips
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: sports
                        .take(3)
                        .map((s) => _chip(s.toString()))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  // Utilization bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Utilization',
                          style: GoogleFonts.dmSans(
                              fontSize: 10, color: AppColors.textMuted)),
                      Text('$util%',
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: util > 80
                                  ? AppColors.red
                                  : AppColors.green)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: util / 100,
                      minHeight: 4,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          util > 80
                              ? AppColors.red
                              : util > 60
                                  ? AppColors.accent
                                  : AppColors.green),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₹${f['price_per_hr']}',
                              style: GoogleFonts.syne(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.green)),
                          Text('/hour',
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                      if (isOpen)
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookingScreen(facility: f),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          child: Text('Book Now',
                              style: GoogleFonts.syne(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.redLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Closed',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.red)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.green)),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
