import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../async_view.dart';
import '../common.dart';
import '../format.dart';
import '../models/student_models.dart';
import '../providers/student_provider.dart';
import 'dashboard.dart';

class LmsScreen extends ConsumerStatefulWidget {
  const LmsScreen({super.key});

  @override
  ConsumerState<LmsScreen> createState() => _LmsScreenState();
}

class _LmsScreenState extends ConsumerState<LmsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(lmsHomeProvider);
    return Scaffold(
      appBar: BlackAppBar('LMS', trailing: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(children: [
          Text(data.hasValue ? 'Semester-${data.requireValue.$1.currentSem}' : '', style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
          const SizedBox(width: 26),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 22),
        ]),
      )),
      body: AsyncBody(
        value: data,
        onRetry: () {
          ref.invalidate(profileProvider);
          ref.invalidate(subjectsProvider);
        },
        builder: (d) => _list(context, d.$1, d.$2),
      ),
    );
  }

  Widget _list(BuildContext context, Profile profile, List<Subject> subjects) => ListView(padding: const EdgeInsets.fromLTRB(8, 7, 8, 8), children: [
          Row(children: [
            Expanded(child: SearchField(onChanged: (v) => setState(() => _query = v.trim().toLowerCase()))),
            const SizedBox(width: 9),
            Container(
              width: 63,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFDDE1E4), borderRadius: BorderRadius.circular(6)),
              child: Text('${subjects.length}\nSubjects',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: AppColors.slate)),
            ),
          ]),
          const SizedBox(height: 11),
          for (final s in subjects)
            if (s.name.toLowerCase().contains(_query) || s.code.toLowerCase().contains(_query)) _card(context, profile, s),
        ]);

  Widget _card(BuildContext context, Profile profile, Subject s) => GestureDetector(
        onTap: () => open(context, LmsSubjectScreen(subject: s)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          height: 93,
          clipBehavior: Clip.antiAlias,
          decoration: cardDecoration(),
          child: Row(children: [
            SizedBox(width: 160, height: 93, child: Image.asset(s.code == '2401CS521' ? 'assets/demo/api_course.png' : img('default_lms_photo.jpg'), fit: BoxFit.cover)),
            const SizedBox(width: 9),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFFEBEA), borderRadius: BorderRadius.circular(8)),
                    child: Text('Sem - ${profile.classLabel}', style: const TextStyle(color: AppColors.red, fontSize: 11.5, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
                  ),
                  Text(s.name, maxLines: 2, style: const TextStyle(fontSize: 15.5, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Colors.black, height: 1.2)),
                  Text(s.code, style: const TextStyle(fontSize: 15.5, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Colors.black)),
                ]),
              ),
            ),
            const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 2, right: 8),
                child: Icon(Icons.chevron_right, color: AppColors.grey, size: 22),
              ),
            ),
          ]),
        ),
      );
}

class LmsSubjectScreen extends ConsumerStatefulWidget {
  const LmsSubjectScreen({super.key, required this.subject, this.initialLab = false});
  final Subject subject;
  final bool initialLab;

  @override
  ConsumerState<LmsSubjectScreen> createState() => _LmsSubjectScreenState();
}

class _LmsSubjectScreenState extends ConsumerState<LmsSubjectScreen> {
  late bool lab = widget.initialLab;

  @override
  Widget build(BuildContext context) {
    final provider = lmsContentProvider(widget.subject.id);
    return Scaffold(
      appBar: BlackAppBar(widget.subject.name, titleSize: 18.5),
      body: AsyncBody(
        value: ref.watch(provider),
        onRetry: () {
          ref.invalidate(profileProvider);
          ref.invalidate(provider);
        },
        builder: (content) {
          final items = lab ? content.labManuals : content.presentations;
          return Column(children: [
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _pill('Presentation (${content.presentations.length})', !lab, () => setState(() => lab = false)),
              const SizedBox(width: 15),
              _pill('Lab Manual (${content.labManuals.length})', lab, () => setState(() => lab = true)),
            ]),
            const SizedBox(height: 9),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                itemCount: items.length,
                itemBuilder: (_, i) => _item(items[i], content.author),
              ),
            ),
          ]);
        },
      ),
      bottomNavigationBar: const _LmsBottomBar(),
    );
  }

  /// Opens the item's file and records that the student has seen it.
  Future<void> _open(ContentItem it) async {
    final messenger = ScaffoldMessenger.of(context);
    void tell(String message) => messenger.showSnackBar(SnackBar(content: Text(message)));
    final url = it.fileUrl;
    if (url == null || url.isEmpty) return tell('No file has been uploaded for this item yet.');
    final repo = ref.read(studentRepoProvider);
    final provider = lmsContentProvider(widget.subject.id);
    final opened = await ref.read(fileOpenerProvider)(resolveApiUrl(url));
    if (!opened) return tell('Could not open this file.');
    try {
      await repo.markSeen(it.id);
      if (mounted) ref.invalidate(provider);
    } on ApiException catch (e) {
      tell(e.message);
    }
  }

  Widget _pill(String text, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.lmsBlue : Colors.transparent,
            border: Border.all(color: AppColors.lmsBlue, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text, style: TextStyle(color: on ? Colors.white : AppColors.lmsBlue, fontSize: 14, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
        ),
      );

  Widget _item(ContentItem it, String author) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(7.5),
        decoration: cardDecoration(radius: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF0EEF5), borderRadius: BorderRadius.circular(5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF2A1A66)),
                const SizedBox(width: 5),
                Text(calendarDate(it.uploadedAt), style: const TextStyle(color: Color(0xFF2A1A66), fontSize: 11.8, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
              ]),
            ),
            const Spacer(),
            if (lab) const Icon(Icons.more_vert, size: 20, color: Colors.black),
          ]),
          const SizedBox(height: 3),
          Text(it.title, style: const TextStyle(color: AppColors.slate, fontSize: 16.4, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
          if (it.subtitle != null) ...[
            const SizedBox(height: 1),
            Text(it.subtitle!, style: const TextStyle(color: Color(0xFF444444), fontSize: 13.7, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
          ],
          if (it.seen) ...[
            const SizedBox(height: 1),
            Text('Seen on ${it.seenAt == null ? '-' : istDate(it.seenAt!)}', style: const TextStyle(color: Color(0xFF444444), fontSize: 14.2, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          ],
          Row(children: [
            Expanded(
              child: Text('By: $author', style: const TextStyle(color: Color(0xFF777777), fontSize: 13.4, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            ),
            GestureDetector(
              key: Key('open-${it.id}'),
              onTap: () => _open(it),
              child: Container(
                height: 25,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(color: const Color(0xFFEAF2F3), borderRadius: BorderRadius.circular(7)),
                child: Row(children: [
                  const Icon(Icons.download, size: 13, color: Color(0xFF3E8A92)),
                  const SizedBox(width: 8),
                  Text(lab ? 'Lab Manual' : 'Presentation',
                      style: const TextStyle(color: Color(0xFF3E8A92), fontSize: 12.8, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
          ]),
        ]),
      );
}

class _LmsBottomBar extends StatelessWidget {
  const _LmsBottomBar();

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black,
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom, top: 12),
        height: 52 + MediaQuery.paddingOf(context).bottom,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _icon('lms_introduction.png'),
          Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 23),
            decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              _icon('lms_content.png'),
              const SizedBox(width: 8),
              const Text('Content', style: TextStyle(color: Colors.white, fontSize: 11.5, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
            ]),
          ),
          _icon('lms_pending_submission.png'),
          _icon('lms_test_mark.png'),
        ]),
      );

  Widget _icon(String n) => Image.asset(img(n), width: 20, height: 20, color: Colors.white);
}
