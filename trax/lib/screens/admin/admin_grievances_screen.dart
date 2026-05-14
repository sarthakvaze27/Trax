import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import 'admin_shell.dart';

class AdminGrievancesScreen extends StatefulWidget {
  const AdminGrievancesScreen({super.key});

  @override
  State<AdminGrievancesScreen> createState() => _AdminGrievancesScreenState();
}

class _AdminGrievancesScreenState extends State<AdminGrievancesScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _grievances = [];
  bool _loading = true;
  String _filter = 'all';
  late TabController _tabCtrl;

  final _filters = ['all', 'open', 'in_progress', 'resolved'];
  final _filterLabels = ['All', 'Open', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    wsService.addUpdateListener(_onWsEvent);
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _filter = _filters[_tabCtrl.index]);
      }
    });
    _load();
  }

  @override
  void dispose() {
    wsService.removeUpdateListener(_onWsEvent);
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onWsEvent(String event, Map<String, dynamic> data) {
    if (event == 'grievance_created' || event == 'grievance_updated') {
      _load(showLoading: false);
    }
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final g = await ApiService.getAdminGrievances();
      if (!mounted) return;
      setState(() {
        _grievances = g;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
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
            content: Text('Status updated to $status',
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

  int _countFor(String f) {
    if (f == 'all') return _grievances.length;
    return _grievances.where((g) => g['status'] == f).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AdminTheme.brand, strokeWidth: 2.5))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AdminTheme.brand,
                    backgroundColor: AdminTheme.surface,
                    child: _filtered.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _grievanceCard(
                              Map<String, dynamic>.from(_filtered[i] as Map),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final openCount = _grievances
        .where((g) => g['status'] == 'open' || g['status'] == 'in_progress')
        .length;

    return Container(
      color: AdminTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grievances',
                        style: GoogleFonts.sora(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.textPrimary,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('${_grievances.length} total  ·  $openCount pending',
                        style: GoogleFonts.sora(
                            fontSize: 12, color: AdminTheme.textSecondary)),
                  ],
                ),
              ),
              if (openCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminTheme.orangeBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AdminTheme.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AdminTheme.orange, size: 14),
                      const SizedBox(width: 5),
                      Text('$openCount open',
                          style: GoogleFonts.sora(
                              fontSize: 11,
                              color: AdminTheme.orange,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AdminTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_filters.length, (i) {
                final active = _filter == _filters[i];
                final count = _countFor(_filters[i]);
                return GestureDetector(
                  onTap: () {
                    _tabCtrl.animateTo(i);
                    setState(() => _filter = _filters[i]);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AdminTheme.brand : AdminTheme.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active ? AdminTheme.brand : AdminTheme.border),
                    ),
                    child: Row(
                      children: [
                        Text(_filterLabels[i],
                            style: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : AdminTheme.textSecondary)),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : AdminTheme.borderMid,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$count',
                                style: GoogleFonts.sora(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? Colors.white
                                        : AdminTheme.textSecondary)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AdminTheme.border, height: 1),
        ],
      ),
    );
  }

  Widget _grievanceCard(Map<String, dynamic> g) {
    final priority = g['priority'] as String? ?? 'medium';
    final status = g['status'] as String? ?? 'open';
    final title = _textValue(g, ['title', 'subject', 'issue_title'],
        fallback: 'Untitled grievance');
    final description =
        _textValue(g, ['description', 'message', 'details'], fallback: '');
    final userName = _nestedTextValue(
      g,
      ['users', 'user', 'submitted_by'],
      ['name', 'full_name', 'email'],
      fallback: 'Anonymous',
    );
    final facilityName = _nestedTextValue(
      g,
      ['facilities', 'facility'],
      ['name', 'facility_name'],
      fallback: '',
    );

    final Map<String, Color> priorityColors = {
      'high': AdminTheme.red,
      'medium': AdminTheme.orange,
      'low': AdminTheme.textMuted,
    };
    final Map<String, Color> priorityBgs = {
      'high': AdminTheme.redBg,
      'medium': AdminTheme.orangeBg,
      'low': AdminTheme.bg,
    };
    final Map<String, Color> statusColors = {
      'open': AdminTheme.red,
      'in_progress': AdminTheme.orange,
      'resolved': AdminTheme.green,
    };

    final pColor = priorityColors[priority] ?? AdminTheme.textMuted;
    final pBg = priorityBgs[priority] ?? AdminTheme.bg;
    final sColor = statusColors[status] ?? AdminTheme.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: pColor, width: 3),
          right: const BorderSide(color: AdminTheme.border),
          top: const BorderSide(color: AdminTheme.border),
          bottom: const BorderSide(color: AdminTheme.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AdminTheme.textPrimary)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: pColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(priority.toUpperCase(),
                      style: GoogleFonts.sora(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: pColor,
                          letterSpacing: 0.8)),
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                      fontSize: 12,
                      color: AdminTheme.textSecondary,
                      height: 1.5)),
            ],

            const SizedBox(height: 10),

            Text(
              facilityName.isEmpty
                  ? 'Submitted by $userName'
                  : 'Submitted by $userName | $facilityName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sora(
                  fontSize: 11, color: AdminTheme.textSecondary),
            ),

            const SizedBox(height: 8),

            // Meta row
            Row(children: [
              const Icon(Icons.person_outline,
                  size: 12, color: AdminTheme.textMuted),
              const SizedBox(width: 4),
              Text(g['users']?['name'] ?? 'Anonymous',
                  style: GoogleFonts.sora(
                      fontSize: 11, color: AdminTheme.textSecondary)),
              if (g['facilities']?['name'] != null) ...[
                Text('  ·  ',
                    style: GoogleFonts.sora(
                        fontSize: 11, color: AdminTheme.textMuted)),
                const Icon(Icons.stadium_outlined,
                    size: 12, color: AdminTheme.textMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(g['facilities']!['name'],
                      style: GoogleFonts.sora(
                          fontSize: 11, color: AdminTheme.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ]),

            const SizedBox(height: 12),

            // Status + Action
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                            color: sColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status == 'in_progress'
                            ? 'IN PROGRESS'
                            : status.toUpperCase(),
                        style: GoogleFonts.sora(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: sColor,
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (status == 'open')
                  _actionChip(
                    'Move to In Progress',
                    AdminTheme.orange,
                    AdminTheme.orangeBg,
                    () => _updateStatus(g['id'], 'in_progress'),
                  ),
                if (status == 'in_progress')
                  _actionChip(
                    'Mark Resolved',
                    AdminTheme.brand,
                    AdminTheme.greenBg,
                    () => _updateStatus(g['id'], 'resolved'),
                  ),
                if (status == 'resolved')
                  Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AdminTheme.brand, size: 14),
                    const SizedBox(width: 5),
                    Text('Resolved',
                        style: GoogleFonts.sora(
                            fontSize: 12,
                            color: AdminTheme.brand,
                            fontWeight: FontWeight.w600)),
                  ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _textValue(
    Map<String, dynamic> source,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return fallback;
  }

  String _nestedTextValue(
    Map<String, dynamic> source,
    List<String> objectKeys,
    List<String> valueKeys, {
    required String fallback,
  }) {
    for (final objectKey in objectKeys) {
      final object = source[objectKey];
      if (object is Map) {
        final mapped = Map<String, dynamic>.from(object);
        final value = _textValue(mapped, valueKeys, fallback: '');
        if (value.isNotEmpty) return value;
      }
    }
    return fallback;
  }

  Widget _actionChip(String label, Color fg, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: GoogleFonts.sora(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
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
              color: AdminTheme.greenBg,
              shape: BoxShape.circle,
              border:
                  Border.all(color: AdminTheme.brand.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: AdminTheme.brand, size: 28),
          ),
          const SizedBox(height: 16),
          Text('All clear!',
              style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.textPrimary)),
          const SizedBox(height: 4),
          Text('No grievances in this category',
              style: GoogleFonts.sora(
                  fontSize: 13, color: AdminTheme.textSecondary)),
        ],
      ),
    );
  }
}
