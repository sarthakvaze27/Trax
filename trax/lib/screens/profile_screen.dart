import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'my_bookings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // Profile hero
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.green, AppColors.greenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        (auth.userName ?? 'U')[0].toUpperCase(),
                        style: GoogleFonts.syne(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(auth.userName ?? 'Athlete',
                      style: GoogleFonts.syne(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('SportSetu Member',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),

          // Loyalty points card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5A623), Color(0xFFE8891A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stars_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Loyalty Points',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: Colors.white70)),
                          Text('${auth.user?['loyalty_points'] ?? 0} pts',
                              style: GoogleFonts.syne(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    Text('Earn 1pt\nper ₹10 spent',
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: Colors.white70,
                            height: 1.4)),
                  ],
                ),
              ),
            ),
          ),

          // Menu items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account',
                      style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecond,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  _menuCard([
                    _menuItem(Icons.person_outline, 'My Profile', 'Manage your details',
                        onTap: () => _showProfileDetails(context, auth)),
                    _menuItem(Icons.bookmark_border, 'My Bookings',
                        'View all your reservations',
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MyBookingsScreen()),
                            )),
                    _menuItem(Icons.stars_outlined, 'Loyalty Rewards',
                        'Redeem your points',
                        onTap: () => _showInfoDialog(
                              context,
                              'Loyalty Rewards',
                              'You have ${auth.user?['loyalty_points'] ?? 0} points. Earn 1 point for every Rs 10 spent on confirmed bookings.',
                            )),
                  ]),
                  const SizedBox(height: 16),
                  Text('Support',
                      style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecond,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  _menuCard([
                    _menuItem(Icons.report_outlined, 'Submit Grievance',
                        'Report a facility issue',
                        onTap: () => _showGrievanceSheet(context)),
                    _menuItem(Icons.help_outline, 'Help & FAQ',
                        'Get answers to common questions',
                        onTap: () => _showInfoDialog(
                              context,
                              'Help & FAQ',
                              'Book a facility from Home, view reservations in My Bookings, and use Friends to chat with other local SportSetu users.',
                            )),
                    _menuItem(Icons.info_outline, 'About SportSetu',
                        'Sports Authority of Goa',
                        onTap: () => _showInfoDialog(
                              context,
                              'About SportSetu',
                              'SportSetu Goa is a Sports Authority of Goa booking and community app for facilities, tournaments, grievances, and local sports friends.',
                            )),
                  ]),
                  const SizedBox(height: 16),
                  Text('App Info',
                      style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecond,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  _menuCard([
                    _menuItem(Icons.phone_outlined, 'SAG Helpline',
                        '0832-2229-XXX',
                        onTap: () => _showInfoDialog(
                              context,
                              'SAG Helpline',
                              'Call 0832-2229-000 for booking and facility support.',
                            )),
                    _menuItem(Icons.language_outlined, 'Website',
                        'sportssetu.goa.gov.in',
                        onTap: () => _showInfoDialog(
                              context,
                              'Website',
                              'Visit sportssetu.goa.gov.in for official Sports Authority of Goa updates.',
                            )),
                  ]),
                  const SizedBox(height: 16),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: Text('Sign Out',
                                style: GoogleFonts.syne(
                                    fontWeight: FontWeight.w700)),
                            content: Text('Are you sure you want to sign out?',
                                style: GoogleFonts.dmSans(fontSize: 13)),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: Text('Cancel',
                                    style: GoogleFonts.dmSans(
                                        color: AppColors.textSecond)),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.red),
                                child: Text('Sign Out',
                                    style: GoogleFonts.dmSans(
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await auth.logout();
                        }
                      },
                      icon: const Icon(Icons.logout, color: AppColors.red),
                      label: Text('Sign Out',
                          style: GoogleFonts.syne(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('SportSetu Goa v1.0.0 · Sports Authority of Goa',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textMuted)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final last = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!last)
                const Divider(
                    height: 0, indent: 56, color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle,
      {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.green50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.green, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
      subtitle: Text(subtitle,
          style:
              GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted)),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 14, color: AppColors.textMuted),
    );
  }

  void _showProfileDetails(BuildContext context, AuthProvider auth) {
    _showInfoDialog(
      context,
      'My Profile',
      'Name: ${auth.userName ?? 'Athlete'}\nEmail: ${auth.user?['email'] ?? ''}\nPhone: ${auth.user?['phone'] ?? ''}\nRole: ${auth.userRole ?? 'user'}',
    );
  }

  void _showInfoDialog(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        content: Text(body, style: GoogleFonts.dmSans(fontSize: 13, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.dmSans(color: AppColors.green)),
          ),
        ],
      ),
    );
  }

  void _showGrievanceSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Submit Grievance',
                    style: GoogleFonts.syne(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                _sheetField(titleCtrl, 'Issue title', Icons.title),
                const SizedBox(height: 10),
                _sheetField(descCtrl, 'Describe the issue', Icons.notes,
                    maxLines: 3),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['low', 'medium', 'high'].map((p) {
                    final active = priority == p;
                    final color = p == 'high'
                        ? AppColors.red
                        : p == 'medium'
                            ? AppColors.accent
                            : AppColors.green;
                    return ChoiceChip(
                      label: Text(p.toUpperCase()),
                      selected: active,
                      selectedColor: color,
                      labelStyle: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textSecond,
                      ),
                      onSelected: (_) => setSheet(() => priority = p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      await ApiService.submitGrievance(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        priority: priority,
                      );
                      if (!ctx.mounted) return;
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Grievance submitted to SAG!'),
                          backgroundColor: AppColors.green,
                        ),
                      );
                    },
                    child: Text('Submit',
                        style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.dmSans(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
