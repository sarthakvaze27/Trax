// Chat Room Screen - Individual chat room screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String title;
  final String subtitle;
  final String avatarInitial;
  final Color avatarColor;
  final String? groupId;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.title,
    required this.subtitle,
    required this.avatarInitial,
    this.avatarColor = AppColors.green,
    this.groupId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final chat = Provider.of<ChatProvider>(context, listen: false);
    chat.fetchHistory(widget.roomId);
    chat.connectRoom(widget.roomId);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    Provider.of<ChatProvider>(context, listen: false).disconnect();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();

    final chat = Provider.of<ChatProvider>(context, listen: false);
    if (widget.groupId != null) {
      chat.sendGroupMessage(widget.groupId!, text);
    } else {
      chat.sendMessage(widget.roomId, text);
    }
    setState(() => _sending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final messages = chat.groupChatHistory[widget.roomId] ?? [];

    // Scroll when new messages arrive
    if (messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.avatarColor.withValues(alpha: 0.7),
              child: Text(widget.avatarInitial,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text(widget.subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ──────────────────────────────────────────────────
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_outlined,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No messages yet',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Start the conversation!',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final isMe = m['isMe'] as bool? ??
                          m['sender_id'] == auth.userId;
                      return _messageBubble(m, isMe);
                    },
                  ),
          ),

          // ── Input bar ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
            decoration: const BoxDecoration(
              color: AppColors.card,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.4),
                            blurRadius: 8)
                      ],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> m, bool isMe) {
    final text = m['text'] as String? ?? '';
    final timestamp = m['timestamp'] as String? ?? '';
    String timeStr = '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      timeStr = '$h:$min';
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.green.withValues(alpha: 0.2),
              child: Text(
                (m['sender_id'] as String? ?? 'U')[0].toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.green : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(text,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isMe
                              ? Colors.white
                              : AppColors.textPrimary,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(timeStr,
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          color: isMe
                              ? Colors.white54
                              : AppColors.textMuted)),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            const Icon(Icons.done_all_rounded,
                size: 14, color: AppColors.green),
          ],
        ],
      ),
    );
  }
}
