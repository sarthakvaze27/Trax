import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';
import '../../services/api_service.dart';

class AdminTournamentsScreen extends StatefulWidget {
  const AdminTournamentsScreen({super.key});

  @override
  State<AdminTournamentsScreen> createState() =>
      _AdminTournamentsScreenState();
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

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final sportCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final prizeCtrl = TextEditingController();
    DateTime startDate = DateTime.now().add(const Duration(days: 7));
    DateTime endDate = DateTime.now().add(const Duration(days: 14));
    int maxTeams = 16;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('New Tournament',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Tournament Name', Icons.emoji_events),
                const SizedBox(height: 10),
                _field(sportCtrl, 'Sport', Icons.sports_soccer),
                const SizedBox(height: 10),
                _field(locationCtrl, 'Location / Venue', Icons.location_on),
                const SizedBox(height: 10),
                _field(prizeCtrl, 'Prize Pool (e.g. ₹50,000)', Icons.currency_rupee),
                const SizedBox(height: 10),
                // Max teams
                Row(children: [
                  const Icon(Icons.groups, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 8),
                  Text('Max Teams:',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecond)),
                  const Spacer(),
                  DropdownButton<int>(
                    value: maxTeams,
                    items: [8, 16, 32, 64].map((v) => DropdownMenuItem(
                        value: v,
                        child: Text('$v',
                            style: GoogleFonts.inter()))).toList(),
                    onChanged: (v) =>
                        setDlg(() => maxTeams = v ?? 16),
                  ),
                ]),
                const SizedBox(height: 10),
                // Dates
                _datePicker(ctx, 'Start Date', startDate, (d) {
                  setDlg(() => startDate = d);
                }),
                const SizedBox(height: 8),
                _datePicker(ctx, 'End Date', endDate, (d) {
                  setDlg(() => endDate = d);
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: AppColors.textSecond)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    sportCtrl.text.trim().isEmpty) {
                  return;
                }
                final navigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                await ApiService.createTournament(
                  name: nameCtrl.text.trim(),
                  sport: sportCtrl.text.trim(),
                  startDate: startDate.toString().substring(0, 10),
                  endDate: endDate.toString().substring(0, 10),
                  location: locationCtrl.text.trim(),
                  maxTeams: maxTeams,
                  prizePool:
                      prizeCtrl.text.trim().isEmpty ? null : prizeCtrl.text.trim(),
                );
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Tournament created!'),
                      backgroundColor: AppColors.green),
                );
                _load();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green),
              child: Text('Create',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Tournaments',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: AppColors.sidebar,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Tournament',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: _tournaments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events_outlined,
                              size: 56, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('No tournaments yet',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Tap + to create one',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _tournaments.length,
                      itemBuilder: (_, i) =>
                          _tournamentCard(_tournaments[i]),
                    ),
            ),
    );
  }

  Widget _tournamentCard(Map<String, dynamic> t) {
    final status = t['status'] as String? ?? 'upcoming';
    final int max = (t['max_teams'] as int?) ?? 16;
    final int reg = (t['registered'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: status == 'ongoing'
                    ? [AppColors.green, AppColors.greenDark]
                    : status == 'upcoming'
                        ? [AppColors.blue, const Color(0xFF0D47A1)]
                        : [Colors.grey.shade600, Colors.grey.shade800],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['name'] ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text('${t['sport']} · ${t['location'] ?? ''}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.white60)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ]),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Info row
                Row(children: [
                  _infoChip(
                      Icons.calendar_month_outlined,
                      '${t['start_date']} → ${t['end_date']}'),
                ]),
                const SizedBox(height: 8),
                if (t['prize_pool'] != null)
                  Row(children: [
                    _infoChip(Icons.workspace_premium_outlined,
                        t['prize_pool']),
                  ]),
                const SizedBox(height: 10),
                // Registration progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Registrations: $reg / $max',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecond)),
                    Text('${max > 0 ? (reg / max * 100).toStringAsFixed(0) : 0}%',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: max > 0 ? (reg / max).clamp(0.0, 1.0) : 0,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.green),
                  ),
                ),
                const SizedBox(height: 12),
                // Status action buttons
                Row(children: [
                  if (status == 'upcoming') ...[
                    Expanded(
                      child: _actionBtn('Mark Ongoing', AppColors.green, () {
                        _updateStatus(t['id'], 'ongoing');
                      }),
                    ),
                  ] else if (status == 'ongoing') ...[
                    Expanded(
                      child: _actionBtn(
                          'Mark Completed', AppColors.textMuted, () {
                        _updateStatus(t['id'], 'completed');
                      }),
                    ),
                  ] else ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppColors.green, size: 14),
                              const SizedBox(width: 6),
                              Text('Completed',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.green,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await ApiService.updateTournamentStatus(id, status);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Tournament marked as $status'),
              backgroundColor: AppColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: AppColors.textSecond),
      const SizedBox(width: 5),
      Text(text,
          style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textSecond)),
    ]);
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.inter(
            fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
          hintText: hint,
          hintStyle:
              GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _datePicker(
    BuildContext ctx,
    String label,
    DateTime current,
    Function(DateTime) onPick,
  ) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: ctx,
          initialDate: current,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (_, child) => Theme(
            data: ThemeData(colorSchemeSeed: AppColors.green),
            child: child!,
          ),
        );
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today,
              color: AppColors.green, size: 16),
          const SizedBox(width: 8),
          Text('$label: ${current.toString().substring(0, 10)}',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textPrimary)),
          const Spacer(),
          const Icon(Icons.edit_calendar, color: AppColors.textMuted, size: 14),
        ]),
      ),
    );
  }
}
