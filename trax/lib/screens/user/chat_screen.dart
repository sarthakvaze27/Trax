// Chat Screen - Main chat screen for user
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'chat_room_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _contacts = [];
  List<dynamic> _groups = [];
  List<dynamic> _broadcasts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final contacts = await ApiService.getChatContacts();
      final groups = await ApiService.getMyGroups();
      final broadcasts = await ApiService.getBroadcasts();
      setState(() {
        _contacts = contacts;
        _groups = groups;
        _broadcasts = broadcasts;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _roomId(String myId, String otherId) {
    final sorted = [myId, otherId]..sort();
    return sorted.join('_');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Messages',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: AppColors.green,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined, color: Colors.white),
            onPressed: _showCreateBroadcast,
          ),
          IconButton(
            icon: const Icon(Icons.group_add_outlined, color: Colors.white),
            onPressed: () => _showCreateGroup(auth.userId ?? ''),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Direct Messages'),
            Tab(text: 'Groups'),
            Tab(text: 'Broadcasts'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.green))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.green,
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildDMList(auth.userId ?? ''),
                  _buildGroupsList(),
                  _buildBroadcastsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildDMList(String myId) {
    if (_contacts.isEmpty) {
      return _empty(
          'No contacts yet', 'Other registered users will appear here');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _contacts.length,
      itemBuilder: (_, i) {
        final c = _contacts[i] as Map<String, dynamic>;
        final name = c['name'] as String? ?? 'User';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        final roomId = _roomId(myId, c['id'] as String);

        return ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                roomId: roomId,
                title: name,
                subtitle: c['email'] as String? ?? '',
                avatarInitial: initial,
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.green,
            child: Text(initial,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          title: Text(name,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          subtitle: Text(c['email'] as String? ?? '',
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 18),
        );
      },
    );
  }

  Widget _buildGroupsList() {
    if (_groups.isEmpty) {
      return _empty('No groups yet', 'Tap + to create a group chat');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _groups.length,
      itemBuilder: (_, i) {
        final g = _groups[i] as Map<String, dynamic>;
        final name = g['name'] as String? ?? 'Group';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';
        final color = Color(int.parse(
            (g['avatar_color'] as String? ?? '#4CAF50')
                .replaceFirst('#', '0xFF')));
        final memberCount = (g['member_ids'] as List<dynamic>?)?.length ?? 0;
        final roomId = 'group_${g['id']}';

        return ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                roomId: roomId,
                title: name,
                subtitle: '$memberCount members',
                avatarInitial: initial,
                avatarColor: color,
                groupId: g['id'] as String?,
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: color,
            child: Text(initial,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          title: Text(name,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          subtitle: Text('$memberCount members',
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 18),
        );
      },
    );
  }

  Widget _buildBroadcastsList() {
    if (_broadcasts.isEmpty) {
      return _empty('No broadcasts yet',
          'Post an open invite when you need more players');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      itemCount: _broadcasts.length,
      itemBuilder: (_, i) {
        final b = _broadcasts[i] as Map<String, dynamic>;
        final title = b['title'] as String? ?? 'Players needed';
        final message = b['message'] as String? ?? '';
        final by = b['created_by_name'] as String? ?? 'Player';
        final facility = b['facility_name'] as String? ?? '';
        final location = b['location'] as String? ?? '';
        final date = b['date'] as String? ?? '';
        final time = b['time_label'] as String? ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.green50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: AppColors.green, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        Text('Posted by $by',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 13, height: 1.35, color: AppColors.textSecond)),
              if (facility.isNotEmpty ||
                  date.isNotEmpty ||
                  time.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (facility.isNotEmpty)
                      _broadcastChip(Icons.stadium_outlined, facility),
                    if (location.isNotEmpty)
                      _broadcastChip(Icons.location_on_outlined, location),
                    if (date.isNotEmpty)
                      _broadcastChip(Icons.calendar_today_outlined, date),
                    if (time.isNotEmpty)
                      _broadcastChip(Icons.schedule_rounded, time),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: message));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Broadcast copied for WhatsApp.'),
                        backgroundColor: AppColors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  label: const Text('Copy for WhatsApp'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: const BorderSide(color: AppColors.green),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _broadcastChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.green),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.green,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showCreateBroadcast() {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('New Broadcast',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              _broadcastField(titleCtrl, 'Title', Icons.campaign_outlined),
              const SizedBox(height: 12),
              _broadcastField(locationCtrl, 'Location e.g. Panaji',
                  Icons.location_on_outlined),
              const SizedBox(height: 12),
              _broadcastField(
                  messageCtrl, 'Message for players', Icons.message_outlined,
                  maxLines: 4),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty ||
                        messageCtrl.text.trim().isEmpty) {
                      return;
                    }
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    await ApiService.createBroadcast(
                      title: titleCtrl.text.trim(),
                      message: messageCtrl.text.trim(),
                      location: locationCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('Broadcast posted.'),
                          backgroundColor: AppColors.green),
                    );
                    _load();
                  },
                  icon: const Icon(Icons.campaign_rounded, size: 18),
                  label: const Text('Post Broadcast'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _broadcastField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        ),
      ),
    );
  }

  void _showCreateGroup(String myId) {
    final nameCtrl = TextEditingController();
    final Set<String> selectedIds = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Create Group',
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                // Name field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Group name',
                      hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                      prefixIcon: const Icon(Icons.group_outlined,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Add Members',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecond)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (_, i) {
                      final c = _contacts[i] as Map<String, dynamic>;
                      final cId = c['id'] as String;
                      final sel = selectedIds.contains(cId);
                      return CheckboxListTile(
                        value: sel,
                        onChanged: (v) => setSheet(() => v == true
                            ? selectedIds.add(cId)
                            : selectedIds.remove(cId)),
                        title: Text(c['name'] as String? ?? '',
                            style: GoogleFonts.inter(fontSize: 13)),
                        activeColor: AppColors.green,
                        dense: true,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      try {
                        final navigator = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        await ApiService.createGroup(
                          name: nameCtrl.text.trim(),
                          memberIds: selectedIds.toList(),
                        );
                        if (!mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('Group created!'),
                              backgroundColor: AppColors.green),
                        );
                        _load();
                      } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Create Group',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(sub,
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
