// Chat Screen - Main chat screen for user
import 'package:flutter/material.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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
      setState(() {
        _contacts = contacts;
        _groups = groups;
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
            style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: AppColors.green,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
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
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Direct Messages'),
            Tab(text: 'Groups'),
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
                ],
              ),
            ),
    );
  }

  Widget _buildDMList(String myId) {
    if (_contacts.isEmpty) {
      return _empty('No contacts yet',
          'Other registered users will appear here');
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
                style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          title: Text(name,
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          subtitle: Text(c['email'] as String? ?? '',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.textMuted)),
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
        final color =
            Color(int.parse((g['avatar_color'] as String? ?? '#4CAF50')
                .replaceFirst('#', '0xFF')));
        final memberCount =
            (g['member_ids'] as List<dynamic>?)?.length ?? 0;
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
                style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          title: Text(name,
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          subtitle: Text('$memberCount members',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.textMuted)),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 18),
        );
      },
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
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
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
                    style: GoogleFonts.syne(
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
                      hintStyle: GoogleFonts.dmSans(
                          color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                      prefixIcon: const Icon(Icons.group_outlined,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Add Members',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecond)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (_, i) {
                      final c =
                          _contacts[i] as Map<String, dynamic>;
                      final cId = c['id'] as String;
                      final sel = selectedIds.contains(cId);
                      return CheckboxListTile(
                        value: sel,
                        onChanged: (v) =>
                            setSheet(() => v == true
                                ? selectedIds.add(cId)
                                : selectedIds.remove(cId)),
                        title: Text(c['name'] as String? ?? '',
                            style: GoogleFonts.dmSans(fontSize: 13)),
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
                        style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
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
              style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(sub,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
