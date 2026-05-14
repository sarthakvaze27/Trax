import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_bookings_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_facilities_screen.dart';
import 'admin_grievances_screen.dart';
import 'admin_tournaments_screen.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
class AdminTheme {
  // Backgrounds
  static const bg = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const sidebarBg = Color(0xFFFFFFFF);

  // Brand / accent
  static const brand = Color(0xFF16A34A); // forest green
  static const brandLight = Color(0xFFDCFCE7);
  static const brandMid = Color(0xFF22C55E);

  // Text
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  // Borders
  static const border = Color(0xFFE2E8F0);
  static const borderMid = Color(0xFFCBD5E1);

  // Status
  static const blue = Color(0xFF3B82F6);
  static const blueBg = Color(0xFFEFF6FF);
  static const purple = Color(0xFF8B5CF6);
  static const purpleBg = Color(0xFFF5F3FF);
  static const orange = Color(0xFFF59E0B);
  static const orangeBg = Color(0xFFFFFBEB);
  static const red = Color(0xFFEF4444);
  static const redBg = Color(0xFFFEF2F2);
  static const green = Color(0xFF16A34A);
  static const greenBg = Color(0xFFDCFCE7);
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _idx = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminBookingsScreen(),
    AdminFacilitiesScreen(),
    AdminGrievancesScreen(),
    AdminTournamentsScreen(),
  ];

  final _labels = [
    'Dashboard',
    'Bookings',
    'Facilities',
    'Grievances',
    'Tournaments'
  ];
  final _icons = [
    Icons.grid_view_rounded,
    Icons.event_note_outlined,
    Icons.stadium_outlined,
    Icons.report_problem_outlined,
    Icons.emoji_events_outlined,
  ];
  final _selectedIcons = [
    Icons.grid_view_rounded,
    Icons.event_note_rounded,
    Icons.stadium_rounded,
    Icons.report_problem_rounded,
    Icons.emoji_events_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        if (wide) {
          return Scaffold(
            backgroundColor: AdminTheme.bg,
            body: Row(
              children: [
                _SideNav(
                  selectedIndex: _idx,
                  labels: _labels,
                  icons: _icons,
                  selectedIcons: _selectedIcons,
                  onSelect: (i) => setState(() => _idx = i),
                ),
                Expanded(
                  child: IndexedStack(index: _idx, children: _screens),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: AdminTheme.bg,
          body: IndexedStack(index: _idx, children: _screens),
          bottomNavigationBar: _BottomNav(
            selectedIndex: _idx,
            labels: _labels,
            icons: _icons,
            selectedIcons: _selectedIcons,
            onSelect: (i) => setState(() => _idx = i),
          ),
        );
      },
    );
  }
}

// ── Sidebar (wide screens) ──────────────────────────────────────────────────
class _SideNav extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> selectedIcons;
  final ValueChanged<int> onSelect;

  const _SideNav({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.selectedIcons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: AdminTheme.sidebarBg,
        border: Border(
          right: BorderSide(color: AdminTheme.border),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Brand ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AdminTheme.brand,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.track_changes_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 11),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SportSetu',
                              style: GoogleFonts.sora(
                                  color: AdminTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          Text('Admin Portal',
                              style: GoogleFonts.sora(
                                  color: AdminTheme.textMuted,
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AdminTheme.border, height: 1),
                ],
              ),
            ),

            // ── Nav section label ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('MANAGEMENT',
                  style: GoogleFonts.sora(
                      color: AdminTheme.textMuted,
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600)),
            ),

            // ── Nav items ────────────────────────────────────────────────
            for (var i = 0; i < labels.length; i++)
              _NavItem(
                label: labels[i],
                icon: selectedIndex == i ? selectedIcons[i] : icons[i],
                active: selectedIndex == i,
                onTap: () => onSelect(i),
              ),
            const SizedBox(height: 8),
            const Divider(
                color: AdminTheme.border, height: 1, indent: 20, endIndent: 20),
            const SizedBox(height: 8),
            _NavItem(
              label: 'Sign out',
              icon: Icons.logout_rounded,
              active: false,
              onTap: () async => await auth.logout(),
            ),

            const Spacer(),

            // ── User card ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminTheme.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AdminTheme.brandLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (auth.userName ?? 'A')[0].toUpperCase(),
                          style: GoogleFonts.sora(
                              color: AdminTheme.brand,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.userName ?? 'Admin',
                              style: GoogleFonts.sora(
                                  color: AdminTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                          Text('Administrator',
                              style: GoogleFonts.sora(
                                  color: AdminTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async => await auth.logout(),
                      child: const Icon(Icons.logout_rounded,
                          color: AdminTheme.textMuted, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Navigation (mobile) ───────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> selectedIcons;
  final ValueChanged<int> onSelect;

  const _BottomNav({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.selectedIcons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        color: AdminTheme.surface,
        border: Border(top: BorderSide(color: AdminTheme.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              ...List.generate(labels.length, (i) {
                return Expanded(
                  child: _NavItem(
                    label: labels[i],
                    icon: selectedIndex == i ? selectedIcons[i] : icons[i],
                    active: selectedIndex == i,
                    compact: true,
                    onTap: () => onSelect(i),
                  ),
                );
              }),
              Expanded(
                child: _NavItem(
                  label: 'Sign out',
                  icon: Icons.logout_rounded,
                  active: false,
                  compact: true,
                  onTap: () async => await auth.logout(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual nav item ───────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(
          horizontal: compact ? 2 : 10,
          vertical: compact ? 2 : 3,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 12,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: active ? AdminTheme.brandLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      color: active ? AdminTheme.brand : AdminTheme.textMuted,
                      size: 20),
                  const SizedBox(height: 3),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                          color:
                              active ? AdminTheme.brand : AdminTheme.textMuted,
                          fontSize: 9.5,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400)),
                ],
              )
            : Row(
                children: [
                  Icon(icon,
                      color:
                          active ? AdminTheme.brand : AdminTheme.textSecondary,
                      size: 18),
                  const SizedBox(width: 10),
                  Text(label,
                      style: GoogleFonts.sora(
                          color: active
                              ? AdminTheme.brand
                              : AdminTheme.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400)),
                ],
              ),
      ),
    );
  }
}
