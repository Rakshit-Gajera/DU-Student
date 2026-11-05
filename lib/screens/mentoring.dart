import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../async_view.dart';
import '../common.dart';
import '../demo_data.dart';
import '../format.dart';
import '../models/student_models.dart';
import '../providers/student_provider.dart';
import '../ui_kit.dart';

class MentoringScreen extends ConsumerWidget {
  const MentoringScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
        length: 3,
        initialIndex: initialTab,
        child: Scaffold(
          appBar: const BlackAppBar('Mentoring Summary'),
          body: AsyncBody(
            value: ref.watch(mentoringProvider),
            onRetry: () => ref.invalidate(mentoringProvider),
            builder: _body,
          ),
        ),
      );

  Widget _body(MentoringData data) {
    final mentor = data.mentor;
    return Builder(builder: (c) {
            final ctl = DefaultTabController.of(c);
            return AnimatedBuilder(
              animation: ctl,
              builder: (_, _) => ListView(padding: const EdgeInsets.fromLTRB(0, 15, 0, 12), children: [
                if (mentor != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: _profile(mentor)),
                const SizedBox(height: 11),
                TextTabs(tabs: [
                  countTab('Mentoring Details', data.sessions.length),
                  countTab("Mentor's History", data.history.length),
                  const Tab(text: 'Mentor Timetable'),
                ]),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: switch (ctl.index) {
                    0 => Column(children: [for (final e in data.sessions) _entry(e)]),
                    1 => Column(children: [
                        for (final h in data.history)
                          _history(h.toDate == null ? '${calendarDate(h.fromDate)} -' : '${calendarDate(h.fromDate)}  - ${calendarDate(h.toDate!)}', h.meetings, h.mentorName),
                      ]),
                    _ => const _Timetable(),
                  },
                ),
              ]),
            );
          });
  }

  Widget _box(IconData icon, Color c, String label, String value, {double labelSize = 12.3}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(9, 6.5, 9, 6.5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE6E6E6)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 5),
            Flexible(child: Text(label, style: bd(labelSize, c))),
          ]),
          const SizedBox(height: 2),
          Text(value, style: hv(15.2)),
        ]),
      );

  Widget _profile(Mentor m) => Container(
        padding: const EdgeInsets.all(7),
        decoration: cardDecoration(shadow: true),
        child: Column(children: [
          Row(children: [
            const CircleAvatar(radius: 35, backgroundImage: AssetImage(demoPhoto)),
            const SizedBox(width: 22),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${m.name}\n${m.designation ?? ''}', style: bd(15).copyWith(height: 1.3)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF17A2B8), borderRadius: BorderRadius.circular(6)),
                child: Text('Current Mentor', style: bd(10.8, Colors.white)),
              ),
            ]),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(child: _box(Icons.call, AppColors.orange, 'Mobile No.', m.mobile ?? '-')),
            const SizedBox(width: 4),
            Expanded(child: _box(Icons.weekend, AppColors.red, 'Office No.', m.officeNo ?? '-')),
          ]),
          const SizedBox(height: 9),
          _box(Icons.email, const Color(0xFF009688), 'Email', m.email ?? '-'),
          const SizedBox(height: 9),
          _box(Icons.school, Colors.deepPurple, 'Department', m.department ?? '-'),
        ]),
      );

  Widget _entry(MentoringEntry e) => Container(
        margin: const EdgeInsets.only(bottom: 17),
        padding: const EdgeInsets.all(7),
        decoration: cardDecoration(shadow: true),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DateChip(istDateTime(e.when), icon: 17, size: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
            child: Text(e.mentorName, style: hv(18, const Color(0xFF00695C))),
          ),
          _box(Icons.warning_amber, AppColors.red, 'Issue Discussed', e.issue, labelSize: 14.4),
          const SizedBox(height: 9),
          _box(Icons.people_outline, AppColors.blue, 'Parents Description', e.parentsDescription ?? '-', labelSize: 14.4),
          const SizedBox(height: 9),
          _box(Icons.timer_outlined, AppColors.orange, 'Next Meeting', e.nextMeeting == null ? '-' : istDateTime(e.nextMeeting!), labelSize: 14.4),
        ]),
      );

  Widget _history(String range, int n, String name) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
        decoration: cardDecoration(radius: 9, shadow: true).copyWith(color: const Color(0xFFFEF9FA)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            DateChip(range),
            const Spacer(),
            Text('Meetings : $n', style: hv(14.5)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.person_outline, size: 17, color: Color(0xFF00695C)),
            const SizedBox(width: 5),
            Text(name, style: hv(16.5, const Color(0xFF00695C))),
          ]),
        ]),
      );
}

class _Timetable extends StatelessWidget {
  const _Timetable();

  static const _days = [('02', 'Mon'), ('03', 'Tue'), ('04', 'Wed'), ('05', 'Thu'), ('06', 'Fri'), ('07', 'Sat')];
  static const _slots = [
    ('Lecture', '7:45 AM', '8:40 AM', '2601CS102 - Web Designing\n(Lecture)', 'BTech+Hons-1A', 'Auditorium - AUD-5'),
    ('Lecture', '9:50 AM', '10:40 AM', '2605CS103 - WT\n(Lecture)', 'MCA-1', 'Class Rooms - C-106'),
    ('Lab (TA)', '9:50 AM', '11:30 AM', '2601CS102 - Web Designing\n(Lab (TA))', 'BTech+Hons-1A - 7', 'Computer Centre - H-306'),
  ];

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        Row(children: [
          const SizedBox(width: 8),
          const CircleAvatar(radius: 15, backgroundColor: Color(0xFF6CC3BA), child: Icon(Icons.calendar_month, size: 17, color: Color(0xFF00695C))),
          const SizedBox(width: 7),
          Text('05 November 2026', style: hv(21)),
        ]),
        const SizedBox(height: 10),
        Container(
          height: 54,
          decoration: cardDecoration(radius: 7),
          padding: const EdgeInsets.only(left: 20),
          child: Row(children: [
            const SizedBox(width: 28, child: Icon(Icons.chevron_left, size: 26, color: Colors.black)),
            for (final d in _days)
              SizedBox(
                width: 51,
                child: Center(
                  child: Container(
                    width: 35,
                    height: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: d.$1 == '05' ? Colors.black : null, borderRadius: BorderRadius.circular(18)),
                    child: Text('${d.$1}\n${d.$2}',
                        textAlign: TextAlign.center,
                        style: bd(12.7, d.$1 == '05' ? Colors.white : const Color(0xFF777777))),
                  ),
                ),
              ),
            const SizedBox(width: 26, child: Icon(Icons.chevron_right, size: 26, color: Colors.black)),
          ]),
        ),
        const SizedBox(height: 14),
        for (final s in _slots)
          Container(
            height: 91,
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: cardDecoration(radius: 7),
            child: Row(children: [
              SizedBox(
                width: 99,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFE0F4F7), borderRadius: BorderRadius.circular(3)),
                    child: Text(s.$1, style: bd(13.5, const Color(0xFF17A2B8))),
                  ),
                  const SizedBox(height: 2),
                  Text('${s.$2}\nto\n${s.$3}', textAlign: TextAlign.right, style: bd(13.8).copyWith(height: 1.27)),
                ]),
              ),
              const SizedBox(width: 7),
              Container(width: 1, color: const Color(0xFFBBBBBB)),
              const SizedBox(width: 7),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.$4, style: hv(11.2).copyWith(height: 1.15)),
                  Text(s.$5, style: bd(11.2, const Color(0xFF444444))),
                  Text(s.$6, style: bd(14)),
                ]),
              ),
            ]),
          ),
      ]);
}
