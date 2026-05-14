import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'admin_shell.dart';

class AdminTournamentsScreen extends StatefulWidget {
  const AdminTournamentsScreen({super.key});

  @override
  State<AdminTournamentsScreen> createState() => _AdminTournamentsScreenState();
}

class _AdminTournamentsScreenState extends State<AdminTournamentsScreen> {
  List<dynamic> _tournaments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final t = await ApiService.getTournaments();
      setState(() {
        _tournaments = t;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await ApiService.updateTournamentStatus(id, status);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tournament updated to $status',
                style: GoogleFonts.sora(fontSize: 13, color: Colors.white)),
            backgroundColor: AdminTheme.brand,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final sportCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final prizeCtrl = TextEditingController();
    DateTime startDate = DateTime.now().add(const Duration(days: 7));
    DateTime endDate = DateTime.now().add(const Duration(days: 14));
    int maxTeams = 16;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, __, ___) => StatefulBuilder(
        builder: (ctx, setDlg) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: AdminTheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AdminTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('New Tournament',
                            style: GoogleFonts.sora(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AdminTheme.textPrimary)),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AdminTheme.bg,
                              shape: BoxShape.circle,
                              border: Border.all(color: AdminTheme.border),
                            ),
                            child: const Icon(Icons.close,
                                color: AdminTheme.textMuted, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _dlgLabel('Tournament Name'),
                    _lightInput(nameCtrl, 'e.g. Goa Premier League',
                        Icons.emoji_events_outlined),
                    const SizedBox(height: 14),
                    _dlgLabel('Sport'),
                    _lightInput(
                        sportCtrl, 'e.g. Football', Icons.sports_soccer),
                    const SizedBox(height: 14),
                    _dlgLabel('Venue / Location'),
                    _lightInput(locationCtrl, 'e.g. Panaji Sports Complex',
                        Icons.location_on_outlined),
                    const SizedBox(height: 14),
                    _dlgLabel('Prize Pool (optional)'),
                    _lightInput(prizeCtrl, 'e.g. ₹1,00,000',
                        Icons.workspace_premium_outlined),
                    const SizedBox(height: 14),
                    _dlgLabel('Max Teams'),
                    Container(
                      decoration: BoxDecoration(
                        color: AdminTheme.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.borderMid),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: maxTeams,
                          isExpanded: true,
                          dropdownColor: AdminTheme.surface,
                          style: GoogleFonts.sora(
                              fontSize: 14, color: AdminTheme.textPrimary),
                          items: [8, 16, 32, 64]
                              .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('$v teams'),
                                  ))
                              .toList(),
                          onChanged: (v) => setDlg(() => maxTeams = v ?? 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _dlgLabel('Start Date'),
                            _datePicker(ctx, startDate, (d) {
                              setDlg(() => startDate = d);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _dlgLabel('End Date'),
                            _datePicker(ctx, endDate, (d) {
                              setDlg(() => endDate = d);
                            }),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty ||
                              sportCtrl.text.trim().isEmpty) {
                            return;
                          }
                          final navigator = Navigator.of(ctx);
                          await ApiService.createTournament(
                            name: nameCtrl.text.trim(),
                            sport: sportCtrl.text.trim(),
                            startDate: startDate.toString().substring(0, 10),
                            endDate: endDate.toString().substring(0, 10),
                            location: locationCtrl.text.trim(),
                            maxTeams: maxTeams,
                            prizePool: prizeCtrl.text.trim().isEmpty
                                ? null
                                : prizeCtrl.text.trim(),
                          );
                          if (!mounted) return;
                          navigator.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tournament created!',
                                  style: GoogleFonts.sora(
                                      fontSize: 13, color: Colors.white)),
                              backgroundColor: AdminTheme.brand,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          _load();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.brand,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text('Create Tournament',
                            style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AdminTheme.brand, strokeWidth: 2.5))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AdminTheme.brand,
                    backgroundColor: AdminTheme.surface,
                    child: _tournaments.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                            itemCount: _tournaments.length,
                            itemBuilder: (_, i) =>
                                _tournamentCard(_tournaments[i]),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AdminTheme.brand,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        label: Text('New Tournament',
            style: GoogleFonts.sora(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 13)),
      ),
    );
  }

  Widget _buildHeader() {
    final upcoming =
        _tournaments.where((t) => t['status'] == 'upcoming').length;
    final ongoing = _tournaments.where((t) => t['status'] == 'ongoing').length;

    return Container(
      color: AdminTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tournaments',
              style: GoogleFonts.sora(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.textPrimary,
                  letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Row(children: [
            _headerPill(
                '$upcoming upcoming', AdminTheme.blue, AdminTheme.blueBg),
            const SizedBox(width: 8),
            if (ongoing > 0)
              _headerPill(
                  '$ongoing live', AdminTheme.brand, AdminTheme.greenBg),
          ]),
          const SizedBox(height: 4),
          const Divider(color: AdminTheme.border, height: 1),
        ],
      ),
    );
  }

  Widget _headerPill(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.sora(
              fontSize: 10, color: fg, fontWeight: FontWeight.w700)),
    );
  }

  Widget _tournamentCard(Map<String, dynamic> t) {
    final status = t['status'] as String? ?? 'upcoming';
    final int max = (t['max_teams'] as int?) ?? 16;
    final int reg = (t['registered'] as int?) ?? 0;
    final double fill = max > 0 ? (reg / max).clamp(0.0, 1.0) : 0;

    final Map<String, Color> statusColors = {
      'upcoming': AdminTheme.blue,
      'ongoing': AdminTheme.brand,
      'completed': AdminTheme.textMuted,
    };
    final Map<String, Color> statusBgs = {
      'upcoming': AdminTheme.blueBg,
      'ongoing': AdminTheme.greenBg,
      'completed': AdminTheme.bg,
    };

    final sColor = statusColors[status] ?? AdminTheme.textMuted;
    final sBg = statusBgs[status] ?? AdminTheme.bg;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        children: [
          // ── Header band ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color:
                  status == 'ongoing' ? AdminTheme.greenBg : AdminTheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border: status == 'ongoing'
                  ? const Border(bottom: BorderSide(color: AdminTheme.border))
                  : null,
            ),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: sBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sColor.withValues(alpha: 0.25)),
                ),
                child:
                    Icon(Icons.emoji_events_rounded, color: sColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['name'] ?? '',
                        style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${t['sport']}  ·  ${t['location'] ?? ''}',
                        style: GoogleFonts.sora(
                            fontSize: 11, color: AdminTheme.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: sBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sColor.withValues(alpha: 0.3)),
                ),
                child: Text(status.toUpperCase(),
                    style: GoogleFonts.sora(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: sColor,
                        letterSpacing: 0.8)),
              ),
            ]),
          ),

          // ── Details ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              children: [
                // Date row
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: AdminTheme.textMuted),
                  const SizedBox(width: 6),
                  Text('${t['start_date']}  →  ${t['end_date']}',
                      style: GoogleFonts.sora(
                          fontSize: 11, color: AdminTheme.textSecondary)),
                  if (t['prize_pool'] != null) ...[
                    const Spacer(),
                    const Icon(Icons.workspace_premium_outlined,
                        size: 12, color: AdminTheme.orange),
                    const SizedBox(width: 5),
                    Text(t['prize_pool'],
                        style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AdminTheme.orange)),
                  ],
                ]),
                const SizedBox(height: 14),

                // Registration progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Registrations: $reg / $max',
                        style: GoogleFonts.sora(
                            fontSize: 11, color: AdminTheme.textSecondary)),
                    Text('${(fill * 100).toStringAsFixed(0)}% full',
                        style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: fill > 0.8
                                ? AdminTheme.red
                                : AdminTheme.brand)),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fill,
                    minHeight: 5,
                    backgroundColor: AdminTheme.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        fill > 0.8 ? AdminTheme.red : AdminTheme.brand),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Action ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(children: [
              if (status == 'upcoming')
                Expanded(
                  child: _actionBtn(
                    'Mark as Ongoing',
                    AdminTheme.brand,
                    AdminTheme.greenBg,
                    AdminTheme.brand.withValues(alpha: 0.3),
                    () => _updateStatus(t['id'], 'ongoing'),
                  ),
                ),
              if (status == 'ongoing')
                Expanded(
                  child: _actionBtn(
                    'Mark as Completed',
                    AdminTheme.textSecondary,
                    AdminTheme.bg,
                    AdminTheme.borderMid,
                    () => _updateStatus(t['id'], 'completed'),
                  ),
                ),
              if (status == 'completed')
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AdminTheme.greenBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AdminTheme.brand, size: 14),
                          const SizedBox(width: 6),
                          Text('Tournament Completed',
                              style: GoogleFonts.sora(
                                  fontSize: 12,
                                  color: AdminTheme.brand,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      String label, Color fg, Color bg, Color border, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.sora(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AdminTheme.blueBg,
              shape: BoxShape.circle,
              border: Border.all(color: AdminTheme.blue.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: AdminTheme.blue, size: 28),
          ),
          const SizedBox(height: 16),
          Text('No tournaments yet',
              style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.textPrimary)),
          const SizedBox(height: 4),
          Text('Tap the button below to create one',
              style: GoogleFonts.sora(
                  fontSize: 13, color: AdminTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _dlgLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label,
          style: GoogleFonts.sora(
              fontSize: 11,
              color: AdminTheme.textSecondary,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _lightInput(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.borderMid),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.sora(fontSize: 14, color: AdminTheme.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AdminTheme.textMuted, size: 16),
          hintText: hint,
          hintStyle:
              GoogleFonts.sora(fontSize: 14, color: AdminTheme.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _datePicker(
      BuildContext ctx, DateTime current, Function(DateTime) onPick) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: ctx,
          initialDate: current,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (_, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: AdminTheme.brand,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AdminTheme.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AdminTheme.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminTheme.borderMid),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              color: AdminTheme.brand, size: 14),
          const SizedBox(width: 8),
          Text(current.toString().substring(0, 10),
              style: GoogleFonts.sora(
                  fontSize: 12, color: AdminTheme.textPrimary)),
        ]),
      ),
    );
  }
}
