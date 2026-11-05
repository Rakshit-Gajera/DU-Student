import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fit', (t) async {
    const faces = ['Regular', 'Medium', 'SemiBold', 'Bold'];
    for (final w in faces) {
      await (FontLoader('Quicksand$w')..addFont(rootBundle.load('assets/fonts/Quicksand-$w.ttf'))).load();
    }
    final samples = jsonDecode(File('test/goldens/out/fit_samples.json').readAsStringSync()) as List;
    final rows = <Widget>[];
    final meta = [];
    for (final s in samples) {
      for (final f in faces) {
        for (final fake in [false, true]) {
          TextStyle st(double size) => TextStyle(fontFamily: 'Quicksand$f', fontWeight: fake ? FontWeight.w900 : FontWeight.w400, fontSize: size, color: Colors.black);
          final tp = TextPainter(text: TextSpan(text: s['text'], style: st(20)), textDirection: TextDirection.ltr)..layout();
          final size = 20 * (s['width'] as num) / tp.width;
          meta.add({'name': s['name'], 'face': f, 'fake': fake, 'size': size});
          rows.add(SizedBox(height: 40, child: Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 6), child: Text(s['text'], maxLines: 1, softWrap: false, style: st(size))))));
        }
      }
    }
    File('test/goldens/out/fit_meta.json').writeAsStringSync(jsonEncode(meta));
    t.view.physicalSize = Size(1500, rows.length * 120.0);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: Material(color: Colors.white, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows))));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/out/fit.png'));
  });
}
