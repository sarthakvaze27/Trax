import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/facility_provider.dart';
import 'booking/booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search = '';
  String _selectedSport = 'All';

  final List<String> _sports = [
    'All', 'Football', 'Cricket', 'Badminton',
    'Basketball', 'Swimming', 'Volleyball', 'Athletics',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FacilityProvider>(context, listen: false).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth     = Provider.of<AuthProvider>(context);
    final provider = Provider.of<FacilityProvider>(context);

    final filtered = provider.facilities.where((f) {
      final matchName = f['name'].toString().toLowerCase()
          .contains(_search.toLowerCase());
      final sports = (f['sports'] as List<dynamic>? ?? []).map((s) => s.toString());
      final matchSport = _selectedSport == 'All' ||
          sports.contains(_selectedSport);
      return matchName && matchSport;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────────
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, ${auth.userName?.split(' ').first ?? 'Athlete'} 👋',
                              style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          Text('Book your sport facility today',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.white60)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search facilities...',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textMuted, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Sport filter chips ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              height: 44,
              margin: const EdgeInsets.only(top: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _sports.length,
                itemBuilder: (_, i) {
                  final s = _sports[i];
                  final selected = _selectedSport == s;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSport = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.green : AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.green
                              : AppColors.border,
                        ),
                      ),
                      child: Text(s,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecond)),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Section header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${filtered.length} Facilities',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  // Real-time indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text('Live',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green)),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // ── Facility list ─────────────────────────────────────────────────
          provider.loading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.green),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _facilityCard(context, filtered[i]),
                    childCount: filtered.length,
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _facilityCard(BuildContext context, Map<String, dynamic> f) {
    final isOpen   = f['is_open'] as bool? ?? true;
    final sports   = (f['sports'] as List<dynamic>? ?? []);
    final amenities = (f['amenities'] as List<dynamic>? ?? []);

    return GestureDetector(
      onTap: isOpen
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BookingScreen(facility: f)),
              )
          : null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)
          ],
        ),
        child: Column(
          children: [
            // Header gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOpen
                      ? [AppColors.green, AppColors.greenDark]
                      : [Colors.grey.shade500, Colors.grey.shade700],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(children: [
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
                      Text(f['location'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.white60)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(isOpen ? 'OPEN' : 'CLOSED',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Price + rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '₹${f['price_per_hr']}',
                              style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.green),
                            ),
                            TextSpan(
                              text: '/hr',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.accent, size: 16),
                        const SizedBox(width: 3),
                        Text('${f['rating']}',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Sports
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      children: sports
                          .take(3)
                          .map((s) => _tag(s.toString()))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Amenities
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amenities.take(3).join(' · '),
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                  if (isOpen) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BookingScreen(facility: f)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Book Now',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: AppColors.green50,
            borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.green)),
      );
}
