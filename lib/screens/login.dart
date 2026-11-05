import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../common.dart';
import '../demo_data.dart';
import '../providers/auth_provider.dart';
import '../ui_kit.dart';
import 'dashboard.dart';

const _fieldBorder = Color(0xFFCDCDCD);
const _hint = Color(0xFF6F6F6F);
const _link = Color(0xFF4763FE);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _remember = true;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final identifier = _identifier.text.trim();
    if (identifier.isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your login details and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(identifier, _password.text, remember: _remember);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not log in. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _forgotPassword() => showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Forgot Password', style: hv(18)),
          content: Text('Please contact the university administration. They can set a new password for your account.', style: bd(14, const Color(0xFF444444))),
          actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK'))],
        ),
      );

  Widget _field({required Key key, required TextEditingController controller, required IconData icon, required String hint, bool obscure = false, TextInputAction? action, ValueChanged<String>? onSubmitted, List<String>? autofill}) {
    const hintStyle = TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w400, fontSize: 14.2, color: _hint);
    return Container(
      height: 60,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _fieldBorder), borderRadius: BorderRadius.circular(9.5)),
      child: Row(children: [
        const SizedBox(width: 10),
        SizedBox(width: 23, child: Icon(icon, size: 23, color: Colors.black)),
        const SizedBox(width: 10.5),
        Expanded(
          child: Stack(alignment: Alignment.centerLeft, children: [
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (_, value, _) => value.text.isNotEmpty
                  ? const SizedBox.shrink()
                  : Text.rich(TextSpan(children: [
                      TextSpan(text: hint, style: hintStyle),
                      TextSpan(text: ' ', style: hintStyle.copyWith(fontSize: 8)),
                      TextSpan(text: '*', style: hintStyle.copyWith(color: AppColors.red)),
                    ])),
            ),
            Semantics(
              label: hint,
              child: TextField(
                key: key,
                controller: controller,
                obscureText: obscure,
                textInputAction: action,
                onSubmitted: onSubmitted,
                autofillHints: autofill,
                style: const TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w400, fontSize: 15.7, color: Colors.black),
                decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 8),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height,
            child: Stack(children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 230,
                child: ClipPath(clipper: _HeaderCurve(), child: const ColoredBox(color: Colors.black)),
              ),
              Positioned(
                top: top,
                left: 0,
                right: 0,
                height: 120.6,
                child: const Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('Darshan University', style: TextStyle(fontFamily: 'QuicksandSemiBold', fontWeight: FontWeight.w400, fontSize: 32.4, height: 1.2, color: Colors.white)),
                  SizedBox(height: 0),
                  Text('Login to your GNUMS ERP', style: TextStyle(fontFamily: 'QuicksandRegular', fontWeight: FontWeight.w400, fontSize: 10.8, height: 1.3, color: Colors.white)),
                ]),
              ),
              Positioned(
                top: 206.5,
                left: 27,
                right: 27,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 9, offset: Offset(0, 4))],
                  ),
                  child: AutofillGroup(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _field(
                        key: const Key('enrollment'),
                        controller: _identifier,
                        icon: Icons.email,
                        hint: 'Email/Mobile No./Enrollment No.',
                        action: TextInputAction.next,
                        autofill: const [AutofillHints.username],
                      ),
                      const SizedBox(height: 8.5),
                      _field(
                        key: const Key('password'),
                        controller: _password,
                        icon: Icons.lock,
                        hint: 'Enter Password',
                        obscure: true,
                        action: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        autofill: const [AutofillHints.password],
                      ),
                      const SizedBox(height: 8.9),
                      GestureDetector(
                        key: const Key('remember'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _remember = !_remember),
                        child: SizedBox(
                          height: 45,
                          child: Row(children: [
                            const SizedBox(width: 11),
                            Icon(_remember ? Icons.check_box : Icons.check_box_outline_blank, size: 22, color: Colors.black),
                            const SizedBox(width: 10.5),
                            const Text('Remember Me', style: TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w400, fontSize: 14, color: Colors.black)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        key: const Key('login'),
                        onTap: _busy ? null : _submit,
                        child: Container(
                          height: 41.7,
                          padding: const EdgeInsets.only(top: 1),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 2))],
                          ),
                          child: _busy
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                              : const Text('LOGIN', style: TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w400, fontSize: 18.2, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        key: const Key('forgot'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _forgotPassword,
                        child: const Center(
                          child: Text('Forgot Password ?', style: TextStyle(fontFamily: 'QuicksandSemiBold', fontWeight: FontWeight.w400, fontSize: 15.2, height: 1.25, color: _link)),
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_error!, key: const Key('login-error'), textAlign: TextAlign.center, style: bd(13.2, AppColors.red)),
                        ),
                    ]),
                  ),
                ),
              ),
              if (_error == null)
                const Positioned(
                  top: 502,
                  left: 0,
                  right: 0,
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'App Version : '),
                      TextSpan(text: appVersion, style: TextStyle(fontFamily: 'QuicksandBold', color: Color(0xFF4A5560))),
                    ]),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w400, fontSize: 13.85, color: Color(0xFF7B7F86)),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 9,
                child: Center(child: Image.asset('assets/demo/du_logo.jpg', width: 165.6, fit: BoxFit.contain)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Black header whose bottom edge bows downward, behind the card.
class _HeaderCurve extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const edge = 208.0;
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, edge)
      ..quadraticBezierTo(size.width / 2, edge + 46, 0, edge)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
