import 'dart:io';
import 'dart:ui' as ui;

import 'package:du_student_app/api/api_client.dart';
import 'package:du_student_app/async_view.dart';
import 'package:du_student_app/main.dart' as app;
import 'package:du_student_app/screens/dashboard.dart';
import 'package:du_student_app/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Set with --dart-define=E2E_SHOT_DIR=... to save a picture of each step.
const shotDir = String.fromEnvironment('E2E_SHOT_DIR');

/// Drives the real app through its UI, the way a student would.
class Driver {
  Driver(this.t);
  final WidgetTester t;

  Future<void> until(Finder f, {int seconds = 25}) async {
    for (var i = 0; i < seconds * 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
      if (f.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for $f');
  }

  Future<void> untilGone(Finder f, {int seconds = 25}) async {
    for (var i = 0; i < seconds * 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
      if (f.evaluate().isEmpty) return;
    }
    fail('Timed out waiting for $f to disappear');
  }

  /// Lets a page transition finish. The clock on the transport screen never settles.
  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Finder text(String value) => find.textContaining(value, findRichText: true);

  Future<void> see(String value) async {
    await until(text(value));
    expect(text(value), findsWidgets, reason: 'should show "$value"');
  }

  void missing(String value) => expect(text(value), findsNothing, reason: 'should not show "$value"');

  /// Waits for loading to end, and fails if the screen ended on its error card.
  Future<void> loaded() async {
    await untilGone(find.byKey(const Key('skeleton')));
    expect(find.byKey(const Key('error-card')), findsNothing, reason: 'the screen should not show an error');
  }

  Future<void> tapText(String value) async {
    await until(find.text(value));
    await t.tap(find.text(value).last);
    await settle();
  }

  /// For labels built from several text spans.
  Future<void> tapRich(String value) async {
    await until(text(value));
    await t.tap(text(value).last);
    await settle();
  }

  Future<void> tapKey(String key) async {
    await until(find.byKey(Key(key)));
    await t.tap(find.byKey(Key(key)));
    await settle();
  }

  Future<void> back() async {
    await t.tap(find.byIcon(Icons.arrow_back).last);
    await settle();
  }

  /// Dashboard > All Menu > the screen.
  Future<void> open(String menuTitle) async {
    await t.tap(find.byIcon(Icons.menu));
    await settle();
    final entry = find.text(menuTitle);
    await t.scrollUntilVisible(entry, 120, scrollable: find.byType(Scrollable).last);
    await settle();
    await t.tap(entry.last);
    await settle();
    await loaded();
  }

  /// Back to the dashboard from a screen opened with [open].
  Future<void> close() async {
    await back();
    await back();
  }

  Future<void> pullToRefresh() async {
    await t.fling(find.byType(ListView).first, const Offset(0, 500), 1500);
    await settle();
    await until(find.byType(DashboardScreen));
    await settle();
    await settle();
  }

  Future<void> login(String enrollmentNo, String password) async {
    await t.enterText(find.byKey(const Key('enrollment')), enrollmentNo);
    await t.enterText(find.byKey(const Key('password')), password);
    await t.tap(find.byKey(const Key('login')));
    await t.pump();
  }

  Future<void> logout() async {
    await settle();
    await t.tap(find.byType(PhotoAvatar).first);
    await settle();
    await tapKey('logout');
    await until(find.byType(LoginScreen));
  }

  Future<void> fill(String key, String value) async {
    await t.enterText(find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)), value);
    await t.pump();
  }

  Future<void> shot(String name) async {
    if (shotDir.isEmpty) return;
    await t.pump(const Duration(milliseconds: 150));
    final view = t.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final bytes = await t.runAsync(() async {
      final image = await layer.toImage(Offset.zero & t.view.physicalSize);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    File('$shotDir/$name.png').writeAsBytesSync(bytes!);
  }
}

/// Starts the app signed out, on phone proportions.
Future<Driver> startApp(WidgetTester t) async {
  t.view.physicalSize = const Size(848, 1800);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.runAsync(() => SecureTokenStore().clear());
  app.main();
  final d = Driver(t);
  await d.until(find.byType(LoginScreen));
  return d;
}
