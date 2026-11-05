import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../async_view.dart';
import '../common.dart';
import '../format.dart';
import '../models/student_models.dart';
import '../providers/student_provider.dart';
import 'dashboard.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        initialIndex: initialTab,
        child: Scaffold(
          appBar: const BlackAppBar('Attendance'),
          body: Column(children: const [
            SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextTabs(tabs: [Tab(text: 'Current'), Tab(text: 'Previous')]),
            ),
            SizedBox(height: 4),
            Expanded(child: TabBarView(children: [_Current(), _Previous()])),
          ]),
        ),
      );
}

class _Current extends ConsumerWidget {
  const _Current();

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncBody(
        value: ref.watch(attendanceProvider),
        onRetry: () {
          ref.invalidate(profileProvider);
          ref.invalidate(attendanceSummaryProvider);
          ref.invalidate(attendanceProvider);
        },
        builder: (data) => _grid(data.$1.$1, data.$1.$2, data.$2),
      );

  Widget _grid(Profile profile, AttendanceSummary summary, List<AttendanceRow> rows) {
    final slotCount = rows.fold(5, (most, r) => r.slots.length > most ? r.slots.length : most);
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 10), children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: cardDecoration(),
          child: Row(children: [
            SemChip(profile.currentSem),
            const SizedBox(width: 13),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                YearLabel(summary.yearLabel),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: PercentBar(summary.percent)),
                  const SizedBox(width: 9),
                  Text('${summary.percent.toStringAsFixed(2)}%', style: const TextStyle(color: AppColors.green, fontSize: 15, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
                ]),
              ]),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.keyboard_arrow_down, size: 26, color: Colors.black),
            const SizedBox(width: 6),
          ]),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
          decoration: cardDecoration(),
          child: Column(children: [
            Row(children: [
              _stat('Present :', '${summary.present}', summary.total, AppColors.green),
              const SizedBox(width: 20),
              _stat('Absent :', '${summary.absent}', summary.total, AppColors.red),
            ]),
            const SizedBox(height: 5),
            Row(children: [
              _stat('Pending :', '${summary.pending}', summary.total, AppColors.orange),
              const SizedBox(width: 20),
              _stat('No Attendance :', '${summary.noAttendance}', summary.total, AppColors.blue),
            ]),
          ]),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.fromLTRB(7, 11, 7, 0),
          decoration: cardDecoration(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Text('P = Present , A = Absent, NA = No Attendance, - = No Lecture/Lab',
                  style: TextStyle(fontSize: 13.2, height: 1.2, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Colors.black)),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
              height: 45,
              child: Row(children: [
                const Expanded(flex: 90, child: Text('Date', textAlign: TextAlign.center, style: _cell)),
                for (var i = 1; i <= slotCount; i++)
                  Expanded(flex: 60, child: Text('Slot\n$i', textAlign: TextAlign.center, style: _cell)),
              ]),
            ),
            for (final r in rows)
              SizedBox(
                height: 46.2,
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    flex: 90,
                    child: Center(child: Text('${gridDate(r.date)}\n${r.day}', textAlign: TextAlign.center, style: _cell)),
                  ),
                  for (var i = 0; i < slotCount; i++) Expanded(flex: 60, child: _slot(i < r.slots.length ? r.slots[i] : '-')),
                ]),
              ),
          ]),
        ),
      ]);
  }

  static const _cell = TextStyle(fontSize: 14, height: 1.25, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Colors.black);

  Widget _stat(String label, String value, int total, Color c) => Expanded(
        child: Row(children: [
          Expanded(
            child: Text(label, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(color: c, fontSize: 15, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
          ),
          Text.rich(TextSpan(children: [
            TextSpan(text: value, style: TextStyle(color: c, fontSize: 15, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
            TextSpan(text: ' / $total', style: TextStyle(color: c, fontSize: 14, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
          ])),
        ]),
      );

  Widget _slot(String s) {
    final (bg, fg) = switch (s) {
      'NA' => (const Color(0xFFE3F2FD), AppColors.blue),
      'P' => (const Color(0xFFEAF4EA), AppColors.green),
      '-' => (Colors.white, Colors.black),
      _ => (const Color(0xFFFDECEA), AppColors.red),
    };
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(s, style: TextStyle(color: fg, fontSize: 13.5, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
    );
  }
}

class _Previous extends ConsumerWidget {
  const _Previous();

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncBody(
        value: ref.watch(pastSemestersProvider),
        onRetry: () => ref.invalidate(pastSemestersProvider),
        builder: (sems) => ListView(padding: const EdgeInsets.fromLTRB(11, 3, 11, 0), children: [
        for (final s in sems)
          GestureDetector(
            onTap: () => open(context, AttendanceDetailScreen(sem: s)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(7),
              decoration: cardDecoration(),
              child: Row(children: [
                SemChip(s.sem),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      YearLabel(s.year),
                      const Spacer(),
                      const Text('Attendance', style: TextStyle(fontSize: 14.5, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Colors.black)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: PercentBar(s.percent)),
                      const SizedBox(width: 9),
                      Text('${s.percent.toStringAsFixed(2)}%',
                          style: const TextStyle(color: AppColors.green, fontSize: 15, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
      ]),
      );
}

class AttendanceDetailScreen extends ConsumerWidget {
  const AttendanceDetailScreen({super.key, this.sem = const PastSem(4, '2025-26 - Even', 90.03)});
  final PastSem sem;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: const BlackAppBar('Attendance Detail'),
        body: AsyncBody(
          value: ref.watch(courseAttendanceProvider),
          onRetry: () => ref.invalidate(courseAttendanceProvider),
          builder: _table,
        ),
      );

  Widget _table(List<CourseRow> rows) {
    final total = rows.fold(0, (sum, r) => sum + r.total);
    final present = rows.fold(0, (sum, r) => sum + r.present);
    final overall = total == 0 ? 0.0 : present / total * 100;
    const head = TextStyle(fontSize: 12, height: 1.15, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Colors.black);
    Widget c(Widget w, {Alignment a = Alignment.center}) =>
        Padding(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6), child: Align(alignment: a, child: w));
    const greenStyle = TextStyle(color: AppColors.green, fontSize: 11.1, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900);
    const bodyStyle = TextStyle(fontSize: 11.1, height: 1.25, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Colors.black);
    return ListView(padding: const EdgeInsets.fromLTRB(12, 16, 12, 12), children: [
        Row(children: [
          Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8.5),
            color: Colors.black,
            child: Text('Sem-${sem.sem}', style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
          ),
          const SizedBox(width: 9),
          YearLabel(sem.year, color: Colors.black, size: 15),
        ]),
        const SizedBox(height: 2),
        Table(
          border: TableBorder.all(color: const Color(0xFF444444), width: .7),
          columnWidths: const {0: FlexColumnWidth(200), 1: FlexColumnWidth(66.5), 2: FlexColumnWidth(66.5), 3: FlexColumnWidth(67)},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(decoration: const BoxDecoration(color: Color(0xFFD3D3D3)), children: [
              c(const Text('Course', style: head)),
              for (final t in ['Total', 'Present'])
                c(Text.rich(textAlign: TextAlign.center, TextSpan(children: [
                  TextSpan(text: '$t\n', style: head),
                  const TextSpan(text: '(Lect/Lab)', style: TextStyle(fontSize: 10.4, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
                ]))),
              c(const FittedBox(child: Text('Attendance', style: TextStyle(fontSize: 13, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Colors.black)))),
            ]),
            for (final r in rows)
              TableRow(decoration: const BoxDecoration(color: Colors.white), children: [
                c(Text(r.course, style: bodyStyle), a: Alignment.centerLeft),
                c(Text('${r.total}', style: bodyStyle)),
                c(Text('${r.present}', style: bodyStyle)),
                c(Text('${r.percent.toStringAsFixed(2)}%', style: greenStyle), a: Alignment.centerRight),
              ]),
            TableRow(decoration: const BoxDecoration(color: Color(0xFFD3D3D3)), children: [
              c(const Text('Total', style: bodyStyle), a: Alignment.centerRight),
              c(Text('$total', style: bodyStyle)),
              c(Text('$present', style: bodyStyle)),
              c(Text('${overall.toStringAsFixed(2)}%', style: greenStyle), a: Alignment.centerRight),
            ]),
          ],
        ),
      ]);
  }
}
