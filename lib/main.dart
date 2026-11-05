import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'common.dart';
import 'demo_data.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard.dart';
import 'screens/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  // Failures go straight to the error card and its retry button, rather than
  // Riverpod retrying in the background behind a skeleton.
  runApp(ProviderScope(retry: (_, _) => null, child: const DuApp(home: SplashScreen())));
}

ThemeData appTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'QuicksandMedium',
      textTheme: const TextTheme(bodyMedium: TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy, surface: AppColors.bg),
    );

final _rootNavigator = GlobalKey<NavigatorState>();

class DuApp extends ConsumerWidget {
  const DuApp({super.key, required this.home});
  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Logging out or a rejected refresh token, from any screen, returns to login.
    ref.listen(authProvider, (previous, next) {
      if (next == AuthStatus.signedOut && previous == AuthStatus.signedIn) {
        _rootNavigator.currentState?.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      }
    });
    return MaterialApp(
        navigatorKey: _rootNavigator,
        title: 'DU Student (Demo)',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: home,
        // Original keeps a black strip behind the navigation bar.
        builder: (context, child) {
          // Everything is sized for a 424dp wide layout, measured from the
          // original screenshots; scale that to the device's real width.
          final mq = MediaQuery.of(context);
          final scale = mq.size.width / 424;
          final size = mq.size / scale;
          final bottom = mq.padding.bottom / scale;
          return ColoredBox(
            color: Colors.black,
            child: FittedBox(
              fit: BoxFit.fill,
              alignment: Alignment.topLeft,
              child: SizedBox.fromSize(
                size: size,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottom),
                  child: MediaQuery(
                    data: mq.copyWith(
                      size: Size(size.width, size.height - bottom),
                      devicePixelRatio: mq.devicePixelRatio * scale,
                      padding: EdgeInsets.only(top: mq.padding.top / scale),
                      viewPadding: EdgeInsets.only(top: mq.viewPadding.top / scale),
                      viewInsets: mq.viewInsets / scale,
                      textScaler: TextScaler.noScaling,
                    ),
                    child: child!,
                  ),
                ),
              ),
            ),
          );
        },
      );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.autoAdvance = true});
  final bool autoAdvance;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoAdvance) {
      _timer = Timer(const Duration(seconds: 2), _advance);
    }
  }

  Future<void> _advance() async {
    AuthStatus status;
    try {
      status = await ref.read(authProvider.notifier).restore();
    } catch (_) {
      // Unreadable secure storage means there is no usable session.
      status = AuthStatus.signedOut;
    }
    if (!mounted) return;
    final Widget next = status == AuthStatus.signedIn ? const DashboardScreen() : const LoginScreen();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Stack(children: [
          Positioned(top: 0, left: 0, right: 0, height: MediaQuery.paddingOf(context).top, child: const ColoredBox(color: Colors.black)),
          Center(child: Image.asset('assets/demo/du_logo.png', width: 110, height: 129, fit: BoxFit.fill)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'App Version : ', style: TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
                TextSpan(
                    text: appVersion,
                    style: TextStyle(fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: const Color(0xFF4A5560))),
              ]),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.4, fontFamily: 'QuicksandRegular', fontWeight: FontWeight.w900, color: Color(0xFF7B7F86)),
            ),
          ),
        ]),
      );
}
