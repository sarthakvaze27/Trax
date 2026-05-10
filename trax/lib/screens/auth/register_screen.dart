import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app_colors.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _adminCtrl     = TextEditingController();
  bool _obscure        = true;
  bool _showAdminCode  = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _passwordCtrl, _adminCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _error = null);
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Name, email and password are required');
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.register(
        name:      _nameCtrl.text.trim(),
        email:     _emailCtrl.text.trim(),
        password:  _passwordCtrl.text.trim(),
        phone:     _phoneCtrl.text.trim(),
        adminCode: _adminCtrl.text.trim(),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Account',
                style: GoogleFonts.syne(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Join Trax and book facilities across Goa',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 28),

            _field(_nameCtrl, 'Full Name', Icons.person_outline),
            const SizedBox(height: 12),
            _field(_emailCtrl, 'Email', Icons.email_outlined,
                inputType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_phoneCtrl, 'Phone (optional)', Icons.phone_outlined,
                inputType: TextInputType.phone),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textMuted, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  hintText: 'Password',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 14, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () => setState(() => _showAdminCode = !_showAdminCode),
              child: Row(children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('Registering as Admin?',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(
                    _showAdminCode
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textMuted),
              ]),
            ),
            if (_showAdminCode) ...[
              const SizedBox(height: 10),
              _field(_adminCtrl, 'Admin Secret Code', Icons.vpn_key_outlined),
              const SizedBox(height: 4),
              Text('Get this code from SAG IT department',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textMuted)),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.red)),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: auth.loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: auth.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Create Account',
                        style: GoogleFonts.syne(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType inputType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: inputType,
        style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          hintText: hint,
          hintStyle:
              GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
