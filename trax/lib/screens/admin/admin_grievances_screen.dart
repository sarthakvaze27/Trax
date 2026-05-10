import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';
import '../../services/api_service.dart';

class AdminGrievancesScreen extends StatefulWidget {
  const AdminGrievancesScreen({super.key});

  @override
  State<AdminGrievancesScreen> createState() =>
      _AdminGrievancesScreenState();
}

class _AdminGrievancesScreenState extends State<AdminGrievancesScreen> {
  List<dynamic> _grievances = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final g = await ApiService.getAdminGrievances();
      setState(() {
        _grievances = g;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await ApiService.updateGrievanceStatus(id, status);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'all') return _grievances;
    return _grievances.where((g) => g['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Grievances',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: AppColors.sidebar,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: AppColors.sidebar,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in ['all', 'open', 'in_progress', 'resolved'])
                    GestureDetector(
                      onTap: () => setState(() => _filter = s),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _filter == s
                              ? AppColors.accent
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s == 'in_progress'
                              ? 'IN PROGRESS'
                              : s.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _filter == s
                                ? Colors.white
                                : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accent))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.accent,
                    child: _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    size: 48, color: AppColors.green),
                                const SizedBox(height: 12),
                                Text('No grievances here!',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) =>
                                _grievanceCard(_filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _grievanceCard(Map<String, dynamic> g) {
    final priority = g['priority'] ?? 'medium';
    final status = g['status'] ?? 'open';

    final priorityColor = priority == 'high'
        ? AppColors.red
        : priority == 'medium'
            ? AppColors.accent
            : AppColors.textMuted;

    final statusColor = status == 'open'
        ? AppColors.red
        : status == 'in_progress'
            ? AppColors.accent
            : AppColors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: priorityColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
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
                  child: Text(g['title'] ?? '',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(priority.toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: priorityColor)),
                ),
              ],
            ),
            if (g['description'] != null) ...[
              const SizedBox(height: 6),
              Text(g['description'],
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecond)),
            ],
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.person_outline,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(g['users']?['name'] ?? 'Anonymous',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textMuted)),
              if (g['facilities']?['name'] != null) ...[
                Text('  ·  ',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted)),
                const Icon(Icons.stadium_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(g['facilities']!['name'],
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ]),
            const SizedBox(height: 10),
            // Status badge + action buttons
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status == 'in_progress'
                        ? 'IN PROGRESS'
                        : status.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor),
                  ),
                ),
                const Spacer(),
                // Status action buttons
                if (status == 'open')
                  _actionBtn('Mark In Progress', AppColors.accent, () {
                    _updateStatus(g['id'], 'in_progress');
                  }),
                if (status == 'in_progress')
                  _actionBtn('Resolve', AppColors.green, () {
                    _updateStatus(g['id'], 'resolved');
                  }),
                if (status == 'resolved')
                  Row(children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.green, size: 14),
                    const SizedBox(width: 4),
                    Text('Resolved',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.green,
                            fontWeight: FontWeight.w600)),
                  ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      ),
    );
  }
}
