import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app_colors.dart';
import '../../services/api_service.dart';

class ConfirmationScreen extends StatefulWidget {
  final String bookingId;
  final String qrCode;
  final String facilityName;
  final String date;
  final String timeLabel;
  final int totalAmount;
  final String facilityLocation;
  final String paymentMode;
  final int splitCount;
  final int shareAmount;
  final List<dynamic> paymentLinks;
  final String message;

  const ConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.qrCode,
    required this.facilityName,
    required this.date,
    required this.timeLabel,
    required this.totalAmount,
    this.facilityLocation = '',
    this.paymentMode = 'solo',
    this.splitCount = 1,
    this.shareAmount = 0,
    this.paymentLinks = const [],
    required this.message,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _broadcasting = false;

  String get _inviteText {
    return 'Anyone up for a game?\n'
        'I booked ${widget.facilityName} on ${widget.date} at ${widget.timeLabel}.\n'
        'Join me on SportSetu if you want to play.';
  }

  Future<void> _copyInvite() async {
    await Clipboard.setData(ClipboardData(text: _inviteText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite copied. Paste it in WhatsApp or any chat.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  Future<void> _broadcastInvite() async {
    setState(() => _broadcasting = true);
    try {
      await ApiService.createBroadcast(
        title: 'Players needed at ${widget.facilityName}',
        message: _inviteText,
        facilityName: widget.facilityName,
        location: widget.facilityLocation,
        date: widget.date,
        timeLabel: widget.timeLabel,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Broadcast posted for other players.'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
    if (mounted) setState(() => _broadcasting = false);
  }

  void _showBroadcastSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
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
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Broadcast Invite',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(_inviteText,
                style: GoogleFonts.inter(
                    fontSize: 13, height: 1.45, color: AppColors.textSecond)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyInvite,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy for WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _broadcasting ? null : _broadcastInvite,
                    icon: _broadcasting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.campaign_rounded, size: 18),
                    label: const Text('Post Broadcast'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String get _splitText {
    final lines = widget.paymentLinks.map((raw) {
      final link = Map<String, dynamic>.from(raw as Map);
      return 'Player ${link['payer']}: Rs ${link['amount']} - ${link['link']}';
    }).join('\n');
    return 'Split payment for ${widget.facilityName}\n'
        '${widget.date} at ${widget.timeLabel}\n'
        '$lines';
  }

  Future<void> _copySplitLinks() async {
    await Clipboard.setData(ClipboardData(text: _splitText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Split payment links copied. Send them to friends.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.green50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.green, size: 48),
              ),
              const SizedBox(height: 16),
              Text('Booking Confirmed!',
                  style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(widget.message,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecond),
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 20)
                  ],
                ),
                child: Column(
                  children: [
                    Text('Entry QR Code',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecond,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: widget.qrCode,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(widget.qrCode,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecond,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text('Show this QR at the facility entrance',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _row(Icons.sports_soccer, 'Facility', widget.facilityName),
                    const Divider(height: 16, color: AppColors.border),
                    _row(Icons.calendar_today, 'Date', widget.date),
                    const Divider(height: 16, color: AppColors.border),
                    _row(Icons.access_time, 'Time', widget.timeLabel),
                    const Divider(height: 16, color: AppColors.border),
                    _row(
                        Icons.currency_rupee,
                        'Amount Paid',
                        widget.paymentLinks.isEmpty
                            ? 'Rs ${widget.totalAmount}'
                            : 'Rs ${widget.totalAmount} split'),
                    const Divider(height: 16, color: AppColors.border),
                    _row(Icons.confirmation_number_outlined, 'Booking ID',
                        widget.bookingId.substring(0, 8).toUpperCase()),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (widget.paymentLinks.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Group Payment Links',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text(
                          '${widget.splitCount} players · about Rs ${widget.shareAmount} each',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 12),
                      ...widget.paymentLinks.map((raw) {
                        final link = Map<String, dynamic>.from(raw as Map);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Player ${link['payer']} · Rs ${link['amount']}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  await Clipboard.setData(ClipboardData(
                                      text: link['link'] as String? ?? ''));
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Payment link copied.'),
                                      backgroundColor: AppColors.green,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Copy'),
                              ),
                            ],
                          ),
                        );
                      }),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _copySplitLinks,
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          label: const Text('Copy All Links'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(color: AppColors.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified,
                        color: AppColors.green, size: 16),
                    const SizedBox(width: 6),
                    Text(
                        widget.paymentLinks.isEmpty
                            ? 'Payment Successful · Rs ${widget.totalAmount} paid'
                            : 'Group payment links generated',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _showBroadcastSheet,
                  icon: const Icon(Icons.campaign_rounded, size: 20),
                  label: Text('Broadcast Invite',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: const BorderSide(color: AppColors.green, width: 1.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Back to Home',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 12, color: AppColors.textSecond)),
        const Spacer(),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
