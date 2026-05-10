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
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.sidebar,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 12)
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_labels.length, (i) {
                final active = _idx == i;
                return GestureDetector(
                  onTap: () => setState(() => _idx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active ? _selectedIcons[i] : _icons[i],
                          color: active
                              ? AppColors.accent
                              : Colors.white38,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[i],
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: active
                                ? AppColors.accent
                                : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
