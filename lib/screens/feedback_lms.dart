import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../async_view.dart';
import '../common.dart';
import '../format.dart';
import '../models/student_models.dart';
import '../providers/student_provider.dart';
import '../ui_kit.dart';

// ---------------------------------------------------------------- Feedback
const expiredRows = [
  '2301CS302-Database Management System - I-',
  '2301CS302-Database Management System - I-',
  '2301CS302-Database Management System - I-',
  '2301CS302-Database Management System - I-',
  '2301DU004-Office Automation Tools-',
  '2301DU004-Office Automation Tools-',
  '2301DU005-Indian Knowledge System-',
];

const overallRows = [
  ('2026-27 - Odd (Active) | Student | Subject | Course Exit Survey | Darshan University | B.Tech CSE - CSE Sem-5', '15 Oct 26 11:55 AM'),
  ('Feedback 2 | 2026-27 - Odd (Active) | DIET| UG Sem 5 ( 08-09-2026 To 18-09-2026)', '15 Sep 26 10:45 AM'),
  ('Feedback 1 | 2026-27 - Odd (Active) | DIET| UG Sem 5 ( 02-07-2026 To 11-07-2026)', '07 Jul 26 11:07 AM'),
  ('2025-26 - Even (Active) | Student | Subject | Course Exit Survey | BTech + Hons Sem - 4', '03 Apr 26 08:09 AM'),
  ('2025-26 - Even (Active) | DIET | UG Sem 4 ( 03-03-2026 To 11-03-2026) Feedback 2', '09 Mar 26 10:14 AM'),
  ('2025-26 - Even (Active) | DIET - BTech | Sem 4 ( 20-01-2026 To 30-01-2026)', '30 Jan 26 09:20 AM'),
];

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key, this.overall = false});
  final bool overall;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        initialIndex: 1,
        child: Scaffold(
          appBar: const BlackAppBar('Feedback'),
          body: Column(children: [
            const SizedBox(height: 6),
            const Align(alignment: Alignment.centerLeft, child: TextTabs(tabs: [Tab(text: 'Current'), Tab(text: 'Past')])),
            Expanded(child: TabBarView(children: [const EmptyText('No Data Found'), _Past(overall: overall)])),
          ]),
        ),
      );
}

class _Past extends StatefulWidget {
  const _Past({required this.overall});
  final bool overall;

  @override
  State<_Past> createState() => _PastState();
}

class _PastState extends State<_Past> {
  late bool overall = widget.overall;

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          child: Row(children: [
            OutlinePill('Academic', on: !overall, onTap: () => setState(() => overall = false)),
            const SizedBox(width: 6),
            OutlinePill('Overall', on: overall, onTap: () => setState(() => overall = true)),
          ]),
        ),
        Expanded(child: overall ? _overall() : _academic()),
      ]);

  Widget _chev() => const Icon(Icons.keyboard_arrow_up, size: 24, color: Colors.black);

  Widget _head(Widget badge, String text) => Row(children: [
        badge,
        const SizedBox(width: 13),
        Expanded(child: Text(text, style: hv(13.6).copyWith(height: 1.27))),
        const SizedBox(width: 13),
        _chev(),
      ]);

  Widget _academic() => ListView(padding: const EdgeInsets.fromLTRB(16, 9, 16, 8), children: [
        Container(
          padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
          decoration: cardDecoration(radius: 5).copyWith(color: const Color(0xFFF9F9F9)),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 0, 11, 8),
              child: _head(
                Container(
                  width: 27,
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFF23B3B), borderRadius: BorderRadius.circular(9)),
                  child: const Text('!', style: TextStyle(fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Colors.white, fontSize: 18)),
                ),
                '2025-26 - Odd (Active) | Student | Subject | Course Exit Survey | BTech & Hons Sem - 3',
              ),
            ),
            for (final r in expiredRows)
              Container(
                height: 79,
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 7),
                decoration: BoxDecoration(color: const Color(0xFFFBF6F7), borderRadius: BorderRadius.circular(6)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r, maxLines: 1, overflow: TextOverflow.clip, softWrap: false, style: hv(13.6)),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      height: 29,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.red), borderRadius: BorderRadius.circular(5)),
                      child: Text('Expired', style: bd(12, AppColors.red)),
                    ),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Due Date', style: bd(11.7)),
                      Text('04 Oct 25', style: hv(15.5, AppColors.red)),
                    ]),
                  ]),
                ]),
              ),
          ]),
        ),
      ]);

  Widget _overall() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(15, 9, 15, 8),
        itemCount: overallRows.length,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
          decoration: cardDecoration(radius: 5).copyWith(color: const Color(0xFFF9F9F9)),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 0, 11, 7),
              child: _head(
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(color: const Color(0xFF5CC467), borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.check, size: 20, color: Colors.white),
                ),
                overallRows[i].$1,
              ),
            ),
            Container(
              height: 47,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: const Color(0xFFF6F8F6), borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                Container(
                  height: 29,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.green), borderRadius: BorderRadius.circular(5)),
                  child: Text('Filled', style: bd(12, AppColors.green)),
                ),
                const Spacer(),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Filled On', style: bd(11.7)),
                  Text(overallRows[i].$2, style: hv(14.4, AppColors.green)),
                ]),
              ]),
            ),
          ]),
        ),
      );
}

// -------------------------------------------------------- LMS test results
class LmsResultScreen extends ConsumerStatefulWidget {
  const LmsResultScreen({super.key, this.sem, this.openIndex});

  /// Opens on the student's current semester unless this is set.
  final int? sem;
  final int? openIndex;

  @override
  ConsumerState<LmsResultScreen> createState() => _LmsResultScreenState();
}

class _LmsResultScreenState extends ConsumerState<LmsResultScreen> {
  late int? _picked = widget.sem;
  late int? open = widget.openIndex;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Keeps the selected semester pill on screen, as the original does.
  void _reveal() {
    if (!_scroll.hasClients) return;
    final sem = _sem;
    const pill = 86.0;
    final right = (8 - sem + 1) * pill + 10;
    final target = (right - _scroll.position.viewportDimension + 10).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.jumpTo(target);
  }

  int get _sem => _picked ?? ref.read(profileProvider).asData?.value.currentSem ?? 1;

  static const _flex = [64, 83, 88, 77, 67];

  @override
  Widget build(BuildContext context) {
    ref.listen(profileProvider, (_, _) => WidgetsBinding.instance.addPostFrameCallback((_) => _reveal()));
    final sem = _picked ?? ref.watch(profileProvider).asData?.value.currentSem ?? 1;
    return Scaffold(
      appBar: const BlackAppBar('LMS Test Result'),
      body: Column(children: [
        SizedBox(
          height: 66,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(10, 22, 10, 13),
            scrollDirection: Axis.horizontal,
            children: [
              for (var s = 8; s >= 1; s--) ...[
                OutlinePill('Sem  - $s', on: s == sem, onTap: () => setState(() {
                  _picked = s;
                  open = null;
                  _reveal();
                })),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        Expanded(
          child: AsyncBody(
            value: ref.watch(lmsTestResultsProvider),
            onRetry: () {
              ref.invalidate(profileProvider);
              ref.invalidate(lmsTestResultsProvider);
            },
            builder: (results) {
              // The API sends courses in display order.
              final courses = <String, List<LmsTestResult>>{};
              for (final r in results.where((r) => r.semNo == sem)) {
                (courses[r.course] ??= []).add(r);
              }
              final items = courses.entries.toList();
              if (items.isEmpty) return Align(alignment: Alignment.center, child: Text('LMS Mark Not Found', style: hv(18, const Color(0xFF9E9E9E))));
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(15, 4, 15, 8),
                itemCount: items.length,
                itemBuilder: (_, i) => _card(items[i].key, items[i].value, i),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _card(String title, List<LmsTestResult> attempts, int i) {
    final on = open == i;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: cardDecoration(radius: 6).copyWith(color: on ? Colors.white : const Color(0xFFF9F9F9)),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => open = on ? null : i),
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 47),
            padding: const EdgeInsets.only(left: 10, right: 11),
            child: Row(children: [
              Expanded(child: Text(title, style: hv(14).copyWith(height: 1.25))),
              Icon(on ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 24, color: Colors.black),
            ]),
          ),
        ),
        if (on) _table(attempts),
      ]),
    );
  }

  Widget _table(List<LmsTestResult> attempts) {
    final units = <int, List<LmsTestResult>>{};
    for (final a in attempts) {
      (units[a.unit] ??= []).add(a);
    }
    return Padding(
        padding: const EdgeInsets.fromLTRB(9, 0, 9, 9),
        child: Column(children: [
          Container(
            height: 37,
            decoration: BoxDecoration(color: const Color(0xFF8A98AD), borderRadius: BorderRadius.circular(6)),
            child: Row(children: [
              for (final (j, h) in const ['Unit', 'Date', 'Attempt', 'Marks', 'Status'].indexed)
                Expanded(flex: _flex[j], child: Text(h, textAlign: TextAlign.center, style: bd(13.8, Colors.white))),
            ]),
          ),
          for (final (i, unit) in units.entries.indexed)
            Container(
              color: i.isOdd ? const Color(0xFFF2F2F2) : Colors.white,
              child: Row(children: [
                Expanded(flex: _flex[0], child: Text('${unit.key}', textAlign: TextAlign.center, style: bd(11.7))),
                Expanded(
                  flex: _flex[1] + _flex[2] + _flex[3] + _flex[4],
                  child: Column(children: [
                    for (final a in unit.value)
                      SizedBox(
                        height: 34.4,
                        child: Row(children: [
                          Expanded(
                            flex: _flex[1],
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(4)),
                                child: Text(calendarDate(a.testDate), maxLines: 1, style: bd(10.9)),
                              ),
                            ),
                          ),
                          Expanded(flex: _flex[2], child: Text('Attempt - ${a.attemptNo}', textAlign: TextAlign.center, style: bd(12.3))),
                          Expanded(flex: _flex[3], child: Center(child: _status('${a.marks} / ${a.maxMarks}', a.passed, hv(12.8, a.passed ? const Color(0xFF00A84F) : AppColors.red)))),
                          Expanded(flex: _flex[4], child: Center(child: _status(a.passed ? 'Pass' : 'Fail', a.passed, bd(12.3, a.passed ? const Color(0xFF00A84F) : AppColors.red)))),
                        ]),
                      ),
                  ]),
                ),
              ]),
            ),
        ]),
      );
  }

  Widget _status(String t, bool passed, TextStyle s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
        decoration: BoxDecoration(color: passed ? const Color(0xFFE5F7EC) : const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(5)),
        child: Text(t, maxLines: 1, style: s),
      );
}
