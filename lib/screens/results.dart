import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../async_view.dart';
import '../common.dart';
import '../models/student_models.dart';
import '../providers/student_provider.dart';
import '../ui_kit.dart';

const kResultsBg = Color(0xFFFAFAFA);
const kSemTile = Color(0xFF455B7C);

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, this.initialTab = 0, this.openSem});
  final int initialTab;
  final int? openSem;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
        length: 2,
        initialIndex: initialTab,
        child: Scaffold(
          backgroundColor: kResultsBg,
          appBar: const BlackAppBar('Results'),
          body: AsyncBody(
            value: ref.watch(resultsProvider),
            onRetry: () => ref.invalidate(resultsProvider),
            builder: (results) => FieldLabelBg(
              color: kResultsBg,
              child: Column(children: [
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerLeft, child: TextTabs(tabs: [countTab('Transcript', results.semesters.length), const Tab(text: 'Result')])),
                Expanded(child: TabBarView(children: [_Transcript(results: results, openSem: openSem), _ResultTab(results)])),
              ]),
            ),
          ),
        ),
      );
}

class _Transcript extends StatefulWidget {
  const _Transcript({required this.results, this.openSem});
  final ResultsData results;
  final int? openSem;

  @override
  State<_Transcript> createState() => _TranscriptState();
}

class _TranscriptState extends State<_Transcript> {
  late int? open = widget.openSem;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(14, 11, 14, 12), children: [
        Row(children: [
          Expanded(child: _stat('CPI', widget.results.cpi.toStringAsFixed(2), const Color(0xFF33C2A3))),
          const SizedBox(width: 7),
          Expanded(child: _stat('Backlog', '${widget.results.backlogs}', const Color(0xFFF6556F))),
        ]),
        const SizedBox(height: 16),
        Center(child: Text('Sem Wise Result', style: hv(18.2))),
        const SizedBox(height: 13),
        for (final s in widget.results.semesters) _tile(s),
        const SizedBox(height: 18),
        Center(child: Text('Grades Obtained', style: hv(18.2))),
        const SizedBox(height: 7),
        Row(children: [
          for (final g in widget.results.grades) ...[
            Expanded(
              child: Container(
                height: 37,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))]),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(g.grade, style: bd(11, const Color(0xFF666666))),
                  Text('${g.count}', style: hv(14)),
                ]),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 5),
        Center(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '[ Total Subjects: ', style: bd(11, const Color(0xFF444444)).copyWith(fontStyle: FontStyle.italic)),
            TextSpan(text: '${widget.results.totalSubjects}', style: hv(11).copyWith(fontStyle: FontStyle.italic)),
            TextSpan(text: ', Passed: ', style: bd(11, const Color(0xFF444444)).copyWith(fontStyle: FontStyle.italic)),
            TextSpan(text: '${widget.results.passed}', style: hv(11).copyWith(fontStyle: FontStyle.italic)),
            TextSpan(text: ' ]', style: bd(11, const Color(0xFF444444)).copyWith(fontStyle: FontStyle.italic)),
          ])),
        ),
      ]);

  Widget _stat(String label, String v, Color c) => Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: const TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w400, fontSize: 10.3, color: Colors.white70)),
          Text(v, style: const TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w400, fontSize: 18, color: Colors.white)),
        ]),
      );

  Widget _tile(SemResult s) {
    final on = open == s.sem;
    const r = Radius.circular(13);
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: kSemTile, width: on ? 1 : 0), borderRadius: const BorderRadius.all(r)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => open = on ? null : s.sem),
          child: Container(
            height: 54,
            color: kSemTile,
            padding: const EdgeInsets.only(left: 15, right: 13),
            child: Row(children: [
              SizedBox(width: 109, child: Text('Sem - ${s.sem}', style: hv(18.2, Colors.white))),
              SizedBox(
                width: 109,
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'SPI : ', style: bd(12.5, const Color(0xFFB9C4D6))),
                  TextSpan(text: s.spi.toStringAsFixed(2), style: hv(13, Colors.white)),
                ])),
              ),
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'BL :  ', style: bd(12.5, const Color(0xFFB9C4D6))),
                  TextSpan(text: '${s.backlogs}', style: hv(13, Colors.white)),
                ])),
              ),
              Icon(on ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white, size: 24),
            ]),
          ),
        ),
        if (on) ...[
          for (final row in s.rows) _row(row),
        ],
      ]),
    );
  }

  Widget _row(ResultRow r) => Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(2, 2.5, 2, 0),
          height: 24.5,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 4),
          color: const Color(0xFFD5D9E2),
          child: Text('${r.subject}  (${r.code})', maxLines: 1, style: bd(14.1, Colors.black)),
        ),
        SizedBox(
          height: 35.5,
          child: Row(children: [
            _col(90, 'Grade', r.grade, AppColors.green),
            _col(115, 'Exam Season', r.season ?? '-', const Color(0xFF333333)),
            _col(80, 'Attempt No.', '${r.attemptNo}', const Color(0xFF333333)),
          ]),
        ),
      ]);

  Widget _col(int f, String a, String b, Color c) => Expanded(
        flex: f,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(a, style: bd(10.7, const Color(0xFF333333))),
          Text(b, style: bd(10.7, c)),
        ]),
      );
}

class _ResultTab extends StatelessWidget {
  const _ResultTab(this.results);
  final ResultsData results;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(19, 9, 19, 0),
        child: Column(children: [
          SelectField(
            label: 'Exam Result',
            value: 'Select Exam Result',
            border: const Color(0xFFD5D5D5),
            onTap: () => showPicker(context, title: 'Exam Result', hint: 'Select Exam Result', items: ['Select Exam Result', for (final s in results.semesters) s.exam]),
          ),
        ]),
      );
}
