// Booking Screen - Facility booking screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app_colors.dart';
import '../../services/api_service.dart';
import 'confirmation_screen.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> facility;
  const BookingScreen({super.key, required this.facility});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  List<dynamic> _slots   = [];
  Set<String>   _picked  = {};
  bool _loadingSlots     = false;
  bool _booking          = false;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _dateLabel => DateFormat('EEE, MMM d yyyy').format(_selectedDate);

  Future<void> _loadSlots() async {
    setState(() { _loadingSlots = true; _picked = {}; });
    try {
      final s = await ApiService.getSlots(widget.facility['id'], _dateStr);
      setState(() => _slots = s);
    } catch (_) {}
    setState(() => _loadingSlots = false);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (_, child) => Theme(
        data: ThemeData(colorSchemeSeed: AppColors.green),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _loadSlots();
    }
  }

  Future<void> _book() async {
    if (_picked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one slot')));
      return;
    }
    setState(() => _booking = true);
    try {
      // Build label e.g. "08:00 – 10:00"
      final sortedSlots = _picked.toList()..sort();
      final first = int.parse(sortedSlots.first);
      final last  = int.parse(sortedSlots.last) + 1;
      final timeLabel =
          '${first.toString().padLeft(2, '0')}:00 – ${last.toString().padLeft(2, '0')}:00';

      final result = await ApiService.createBooking(
        facilityId: widget.facility['id'],
        date:       _dateStr,
        slots:      sortedSlots,
        timeLabel:  timeLabel,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmationScreen(
              bookingId:    result['booking_id'],
              qrCode:       result['qr_code'],
              facilityName: result['facility_name'],
              date:         result['date'],
              timeLabel:    result['time_label'],
              totalAmount:  result['total_amount'] as int,
              message:      result['message'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
    if (mounted) setState(() => _booking = false);
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.facility;
    final pricePerHr = f['price_per_hr'] as int? ?? 0;
    final total = _picked.length * pricePerHr;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Book Slot',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: AppColors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Facility info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      Text(f['emoji'] ?? '🏟️',
                          style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['name'] ?? '',
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Text(f['location'] ?? '',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecond)),
                            Text('₹$pricePerHr / hour',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Date picker
                  Text('Select Date',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.green, width: 1.5),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.green, size: 18),
                        const SizedBox(width: 10),
                        Text(_dateLabel,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const Spacer(),
                        const Icon(Icons.edit_calendar_outlined,
                            color: AppColors.textMuted, size: 16),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Slots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Available Slots',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Row(children: [
                        _legend(AppColors.green50, AppColors.green, 'Available'),
                        const SizedBox(width: 10),
                        _legend(AppColors.redLight, AppColors.red, 'Booked'),
                        const SizedBox(width: 10),
                        _legend(AppColors.green, AppColors.green, 'Selected'),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _loadingSlots
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.green))
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.4,
                          ),
                          itemCount: _slots.length,
                          itemBuilder: (_, i) {
                            final slot   = _slots[i];
                            final key    = slot['slot_key'] as String;
                            final avail  = slot['available'] as bool;
                            final sel    = _picked.contains(key);

                            Color bg, border, fg;
                            if (!avail) {
                              bg = AppColors.redLight;
                              border = AppColors.red;
                              fg = AppColors.red;
                            } else if (sel) {
                              bg = AppColors.green;
                              border = AppColors.green;
                              fg = Colors.white;
                            } else {
                              bg = AppColors.card;
                              border = AppColors.border;
                              fg = AppColors.textPrimary;
                            }

                            return GestureDetector(
                              onTap: avail
                                  ? () => setState(() {
                                        if (sel) {
                                          _picked.remove(key);
                                        } else {
                                          _picked.add(key);
                                        }
                                      })
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: border, width: 1.2),
                                ),
                                child: Center(
                                  child: Text(
                                    slot['label'].toString().split('–').first.trim(),
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: fg),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),

          // ── Bottom summary bar ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            decoration: const BoxDecoration(
              color: AppColors.card,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4))
              ],
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_picked.length} slot${_picked.length != 1 ? 's' : ''} selected',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textMuted)),
                    Text('₹$total',
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.green)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _booking ? null : _book,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _booking
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Confirm Booking',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color bg, Color border, String label) {
    return Row(children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted)),
    ]);
  }
}
