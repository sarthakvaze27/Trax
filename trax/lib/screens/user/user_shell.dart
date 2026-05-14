import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app_colors.dart';
import '../../providers/facility_provider.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'map_screen.dart';
import 'chat_screen.dart';
import '../profile_screen.dart';
import '../my_bookings_screen.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _idx = 0;

  final _screens = const [
    HomeScreen(),
    ExploreScreen(),
    MapScreen(),
    ChatScreen(),
    MyBookingsScreen(),
    ProfileScreen(),
  ];

  final _labels = const ['Home', 'Explore', 'Map', 'Friends', 'Bookings', 'Profile'];
  final _icons = const [
    Icons.home_outlined,
    Icons.explore_outlined,
    Icons.map_outlined,
    Icons.people_outline,
    Icons.book_online_outlined,
    Icons.person_outline,
  ];
  final _activeIcons = const [
    Icons.home,
    Icons.explore,
    Icons.map,
    Icons.people,
    Icons.book_online,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    // Initial facility load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FacilityProvider>(context, listen: false).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_idx],
      bottomNavigationBar: _UserBottomBar(
        selectedIndex: _idx,
        labels: _labels,
        icons: _icons,
        activeIcons: _activeIcons,
        onSelect: (i) => setState(() => _idx = i),
      ),
    );
  }
}

class _UserBottomBar extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> activeIcons;
  final ValueChanged<int> onSelect;

  const _UserBottomBar({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.activeIcons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 14)],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 7, 6, 8),
          child: Row(
            children: List.generate(labels.length, (i) {
              final active = selectedIndex == i;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.green50 : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active ? activeIcons[i] : icons[i],
                          color: active ? AppColors.green : AppColors.textMuted,
                          size: 21,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            color:
                                active ? AppColors.green : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
