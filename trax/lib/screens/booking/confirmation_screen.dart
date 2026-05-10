import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app_colors.dart';

class ConfirmationScreen extends StatelessWidget {
  final String bookingId;
  final String qrCode;
  final String facilityName;
  final String date;
  final String timeLabel;
  final int totalAmount;
  final String message;

  const ConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.qrCode,
    required this.facilityName,
    required this.date,
    required this.timeLabel,
    required this.totalAmount,
    required this.message,
  });

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
              // Success icon
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
              Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecond),
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),

              // QR Code card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07), blurRadius: 20)
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
                      data: qrCode,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(qrCode,
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

              // Booking details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _row(Icons.sports_soccer, 'Facility', facilityName),
                    const Divider(height: 16, color: AppColors.border),
                    _row(Icons.calendar_today, 'Date', date),
                    const Divider(height: 16, color: AppColors.border),
                    _row(Icons.access_time, 'Time', timeLabel),
                    const Divider(height: 16, color: AppColors.border),
                    _row(Icons.currency_rupee, 'Amount Paid', '₹$totalAmount'),
                    const Divider(height: 16, color: AppColors.border),
                    _row(Icons.confirmation_number_outlined, 'Booking ID',
                        bookingId.substring(0, 8).toUpperCase()),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment badge
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
                    const Icon(Icons.verified, color: AppColors.green, size: 16),
                    const SizedBox(width: 6),
                    Text('Payment Successful · ₹$totalAmount paid',
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
                child: ElevatedButton(
                  onPressed: () {
                    // Pop back to home
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
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
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecond)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
