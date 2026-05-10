// Admin Shell - Main navigation shell for admin
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';
import 'admin_dashboard_screen.dart';
import 'admin_facilities_screen.dart';
import 'admin_grievances_screen.dart';
import 'admin_tournaments_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _idx = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminFacilitiesScreen(),
    AdminGrievancesScreen(),
    AdminTournamentsScreen(),
  ];

  final _labels = ['Dashboard', 'Facilities', 'Grievances', 'Tournaments'];
  final _icons = [
    Icons.dashboard_outlined,
    Icons.stadium_outlined,
    Icons.report_outlined,
    Icons.emoji_events_outlined,
  ];
  final _selectedIcons = [
    Icons.dashboard,
    Icons.stadium,
    Icons.report,
    Icons.emoji_events,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                _AdminSideNav(
                  selectedIndex: _idx,
                  labels: _labels,
                  icons: _icons,
                  selectedIcons: _selectedIcons,
                  onSelect: (i) => setState(() => _idx = i),
                ),
                Expanded(child: IndexedStack(index: _idx, children: _screens)),
              ],
            ),
          );
        }
        return Scaffold(
          body: IndexedStack(index: _idx, children: _screens),
          bottomNavigationBar: _AdminBottomNav(
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

class _AdminSideNav extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> selectedIcons;
  final ValueChanged<int> onSelect;

  const _AdminSideNav({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.selectedIcons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: AppColors.sidebar,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.track_changes,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SportSetu',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      Text('Admin Portal',
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('MANAGEMENT',
                  style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1)),
              const SizedBox(height: 10),
              for (var i = 0; i < labels.length; i++)
                _AdminNavItem(
                  label: labels[i],
                  icon: selectedIndex == i ? selectedIcons[i] : icons[i],
                  active: selectedIndex == i,
                  onTap: () => onSelect(i),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.green,
                      child: Text('SA',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('SAG Admin',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> selectedIcons;
  final ValueChanged<int> onSelect;

  const _AdminBottomNav({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.selectedIcons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: List.generate(labels.length, (i) {
              return Expanded(
                child: _AdminNavItem(
                  label: labels[i],
                  icon: selectedIndex == i ? selectedIcons[i] : icons[i],
                  active: selectedIndex == i,
                  compact: true,
                  onTap: () => onSelect(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : Colors.white54;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(vertical: compact ? 0 : 3),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 12,
          vertical: compact ? 8 : 11,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: fg, size: 21),
                  const SizedBox(height: 3),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: fg,
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500)),
                ],
              )
            : Row(
                children: [
                  Icon(icon, color: fg, size: 20),
                  const SizedBox(width: 10),
                  Text(label,
                      style: GoogleFonts.inter(
                          color: fg,
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500)),
                ],
              ),
      ),
    );
  }
}
