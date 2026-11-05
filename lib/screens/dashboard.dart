import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../async_view.dart';
import '../common.dart';
import '../demo_data.dart';
import '../format.dart';
import '../models/student_models.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import 'all_menu.dart';
import 'attendance.dart';
import 'feedback_lms.dart';
import 'requests.dart';
import 'results.dart';
import 'lms.dart';
import 'mentoring.dart';
import 'transport.dart';

void open(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

/// Opens the screen for a menu title; screens outside the current scope do nothing.
void openMenu(BuildContext context, String title) {
  final page = switch (title) {
    'Attendance' => const AttendanceScreen(),
    'LMS Dashboard' => const LmsScreen(),
    'Mentoring' => const MentoringScreen(),
    'Transport' => const TransportScreen(),
    'Academic Calendar' => const AcademicCalendarScreen(),
    'Results' => const ResultsScreen(),
    'Data Change Request' => const DataChangeScreen(),
    'Feedback' => const FeedbackScreen(),
    'LMS Test Result' => const LmsResultScreen(),
    'Grievance Registration' => const GrievanceScreen(),
    'Exam Schedule' => const ScheduleScreen(),
    'Circular' => const CircularScreen(),
    'Certificate Request' => const CertificateScreen(),
    _ => null,
  };
  if (page != null) open(context, page);
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    return Scaffold(
      body: AsyncBody(
        value: data,
        onRetry: () => _reload(ref),
        skeleton: Padding(padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top), child: const SkeletonList(count: 7)),
        builder: (d) => _body(context, ref, d.$1.$1, d.$1.$2, d.$2),
      ),
    );
  }

  void _reload(WidgetRef ref) {
    ref.invalidate(profileProvider);
    ref.invalidate(subjectsProvider);
    ref.invalidate(attendanceSummaryProvider);
  }

  /// The dashboard stays open under every other screen, so pulling down is how it picks up changes.
  Future<void> _pullToRefresh(WidgetRef ref) async {
    _reload(ref);
    try {
      await ref.read(dashboardProvider.future);
    } catch (_) {
      // The error card takes over from here.
    }
  }

  Widget _body(BuildContext context, WidgetRef ref, Profile profile, List<Subject> subjects, AttendanceSummary summary) => Column(children: [
          _Header(profile),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _pullToRefresh(ref),
              child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.only(bottom: 10), children: [
              _SectionTitle('Attendance', 'ic_attendance.png', onTap: () => openMenu(context, 'Attendance'), top: 5),
              _AttendanceCard(profile.currentSem, summary),
              const _SectionTitle('Time Table', 'ic_timetable.png'),
              const _TimeTable(),
              const _SectionTitle('Upcoming Academic Activities', 'ic_timetable.png', top: 11.5, left: 13),
              const _Activity(),
              _SectionTitle('LMS', 'ic_library.png',
                  badge: 'Sem - ${profile.currentSem}', top: 20, left: 13, onTap: () => openMenu(context, 'LMS Dashboard')),
              _LmsStrip(subjects),
              _SectionTitle('Current Mentor', 'Mentoring.png', top: 16, onTap: () => openMenu(context, 'Mentoring')),
              if (profile.mentor != null) _MentorCard(profile.mentor!),
              _SectionTitle('Data Change Request', 'dataChange.png', left: 18, onTap: () => openMenu(context, 'Data Change Request')),
              const _DataChange(),
              const _SectionTitle('Other', 'more_icon.png', left: 18, top: 20),
              const _OtherGrid(),
            ]),
            ),
          ),
          const SizedBox(
            height: 38,
            child: Align(alignment: Alignment(0, -.75),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: 'App Version: '),
                TextSpan(text: appVersion, style: TextStyle(fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
              ]), style: TextStyle(fontSize: 15, color: AppColors.grey, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
            ),
          ),
        ]);
}

class _Header extends StatelessWidget {
  const _Header(this.profile);
  final Profile profile;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: Colors.black, boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 2)),
        ]),
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top, bottom: 2),
        height: 56 + MediaQuery.paddingOf(context).top,
        child: Row(children: [
          const SizedBox(width: 17),
          GestureDetector(
            onTap: () => _showProfileMenu(context),
            child: PhotoAvatar(url: profile.photoUrl, radius: 22.5),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShaderMask(
                shaderCallback: (r) =>
                    const LinearGradient(colors: [Color(0xFFFFEB3B), Color(0xFFFF7043)]).createShader(r),
                child: Text('Hi, ${profile.name}',
                    style: const TextStyle(fontSize: 19, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Colors.white)),
              ),
              Text(profile.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.7, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Colors.white)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 26),
            onPressed: () => open(context, const AllMenuScreen()),
          ),
        ]),
      );
}

void _showProfileMenu(BuildContext context) => showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.transparent,
      pageBuilder: (_, _, _) => const ProfileMenuOverlay(),
    );

/// Blurred backdrop + profile popup.
class ProfileMenuOverlay extends ConsumerWidget {
  const ProfileMenuOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(color: const Color(0xA6000000)),
          ),
        ),
      ),
      Positioned(
        left: 17,
        top: top + 4,
        child: PhotoAvatar(url: ref.watch(profileProvider).asData?.value.photoUrl, radius: 22.5),
      ),
      Positioned(
        left: 17,
        top: top + 59,
        width: 254,
        child: Material(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _row('Profile', const Icon(Icons.account_circle, size: 23, color: Colors.black87)),
              _row('Change Password', const Icon(Icons.vpn_key, size: 23, color: Colors.black87)),
              _row('Settings', const Icon(Icons.settings_outlined, size: 23, color: Colors.black87)),
              _row('Web Login', const Icon(Icons.web, size: 23, color: Colors.black87)),
              _row('App Lock', Transform.scale(scale: .7, child: Switch(value: false, onChanged: (_) {}, thumbColor: const WidgetStatePropertyAll(Colors.white), trackColor: const WidgetStatePropertyAll(Color(0xFF9E9E9E)), trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent))), medium: true),
              GestureDetector(
                key: const Key('logout'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(authProvider.notifier).logout();
                },
                child: _row('Logout', const Icon(Icons.logout, size: 23, color: Colors.black87)),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _row(String label, Widget trailing, {bool medium = false}) => SizedBox(
        height: 45,
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 17.5,
                      color: Colors.black,
                      fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400))),
          trailing,
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.icon, {this.badge, this.onTap, this.top = 13.5, this.left = 11});
  final double left;
  final double top;
  final String title;
  final String icon;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(left, top, 3, 5.5),
          child: Row(children: [
            Image.asset(img(icon), width: 18, height: 18, color: Colors.black87),
            const SizedBox(width: 9),
            Text(title, style: const TextStyle(fontSize: 19, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Colors.black)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFFE4E1), borderRadius: BorderRadius.circular(5)),
                child: Text(badge!, style: const TextStyle(color: AppColors.red, fontSize: 13, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
              ),
            ],
            const Spacer(),
            const Icon(Icons.chevron_right, size: 30, color: Colors.black),
          ]),
        ),
      );
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard(this.sem, this.summary);
  final int sem;
  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(9, 0, 13, 0),
        padding: const EdgeInsets.all(7),
        decoration: cardDecoration(),
        child: Row(children: [
          Container(
            width: 73,
            height: 53,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFF2F7F7), borderRadius: BorderRadius.circular(8)),
            child: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Semester\n', style: TextStyle(fontSize: 12.6, height: 1.3)),
              TextSpan(text: '$sem', style: const TextStyle(fontSize: 18, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, height: 1.2)),
            ]), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.darkTeal, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(bottom: 3), child: YearLabel(' ${summary.yearLabel}', color: const Color(0xFF555555), size: 16)),
              Row(children: [
                Expanded(child: PercentBar(summary.percent, track: const Color(0xFF9E9E9E))),
                const SizedBox(width: 9),
                Text('${summary.percent.toStringAsFixed(2)}%', style: const TextStyle(color: AppColors.green, fontSize: 18, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
              ]),
            ]),
          ),
        ]),
      );
}

class _TimeTable extends StatelessWidget {
  const _TimeTable();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(children: [
          Row(children: [
            Container(
              width: 88,
              height: 39,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(10))),
              child: const Text('05/11', style: TextStyle(fontSize: 17, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Color(0xFF666666))),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Container(
                height: 39,
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topRight: Radius.circular(10))),
              ),
            ),
          ]),
          const SizedBox(height: 2),
          Container(
            height: 50,
            alignment: Alignment.center,
            decoration: cardDecoration(),
            child: const Text('No TimeTable', style: TextStyle(fontSize: 18.5, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Color(0xFF999999))),
          ),
        ]),
      );
}

class _Activity extends StatelessWidget {
  const _Activity();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(9, 0, 9, 0),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: cardDecoration(),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
            decoration: BoxDecoration(color: const Color(0xFFF2F6F5), borderRadius: BorderRadius.circular(6)),
            child: const Row(children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF4A8F80)),
              SizedBox(width: 4),
              Text('07-12-2026', style: TextStyle(color: Color(0xFF4A8F80), fontSize: 11, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text('Commencement of Next Semester (Tentative)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF4A8F80), fontSize: 15.2, fontFamily: 'QuicksandSemiBold', fontWeight: FontWeight.w900)),
          ),
        ]),
      );
}

class _LmsStrip extends StatelessWidget {
  const _LmsStrip(this.subjects);
  final List<Subject> subjects;

  /// The strip's chosen subjects, or the first four when none of them are offered.
  List<String> get names {
    final chosen = [
      for (final code in dashboardLmsCodes)
        for (final s in subjects)
          if (s.code == code) s.name,
    ];
    return chosen.isNotEmpty ? chosen : subjects.take(4).map((s) => s.name).toList();
  }

  @override
  Widget build(BuildContext context) {
    final names = this.names;
    return SizedBox(
        height: 73,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          scrollDirection: Axis.horizontal,
          itemCount: names.length,
          separatorBuilder: (_, _) => const SizedBox(width: 9),
          itemBuilder: (_, i) => Container(
            width: 141,
            padding: const EdgeInsets.all(9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(img('default_lms_photo.jpg')),
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(Color(0xE61A4844), BlendMode.srcATop),
              ),
            ),
            child: Text(names[i],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
          ),
        ),
      );
  }
}

class _MentorCard extends StatelessWidget {
  const _MentorCard(this.mentor);
  final Mentor mentor;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(7, 0, 14, 0),
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        decoration: cardDecoration(),
        child: Row(children: [
          const CircleAvatar(radius: 37, backgroundImage: AssetImage(demoPhoto)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mentor.name, style: const TextStyle(fontSize: 18.5, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Color(0xFF444444))),
              Text('${initials(mentor.department ?? '')} | ${mentor.designation ?? ''} | ${mentor.officeNo ?? ''}', style: const TextStyle(fontSize: 12.7, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Color(0xFF555555))),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _round(AppColors.green, Icons.call),
                const SizedBox(width: 13),
                _round(const Color(0xFF757575), Icons.email),
                const SizedBox(width: 7),
              ]),
            ]),
          ),
        ]),
      );

  Widget _round(Color c, IconData icon) => CircleAvatar(radius: 14, backgroundColor: c, child: Icon(icon, size: 14, color: Colors.white));
}

class _DataChange extends StatelessWidget {
  const _DataChange();

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(fontSize: 14.5, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Color(0xFF4A4A4A));
    TextStyle n(Color c) => TextStyle(fontSize: 14.5, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: c);
    Widget stat(String t, String v, Color c) => Expanded(
          child: Row(children: [
            const Padding(padding: EdgeInsets.only(right: 8), child: CircleAvatar(radius: 3, backgroundColor: AppColors.grey)),
            Text(t, style: label),
            const Spacer(),
            Text(v, style: n(c)),
            const SizedBox(width: 10),
          ]),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: cardDecoration(radius: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(children: [
          const TextSpan(text: 'Total Data Change Request : ', style: label),
          TextSpan(text: '1', style: n(AppColors.teal)),
        ])),
        const Divider(height: 16, color: Color(0xFFE0E0E0)),
        Row(children: [stat('Approved', '1', AppColors.green), stat('Rejected', '0', AppColors.red)]),
        const SizedBox(height: 3),
        Row(children: [stat('Pending', '0', const Color(0xFFD8A800)), const Spacer()]),
        const Divider(height: 16, color: Color(0xFFE0E0E0)),
        Row(children: [
          const Text('Any Updates Today : ', style: label),
          Text('0', style: n(AppColors.teal)),
          const Spacer(),
          const Text('Count : ', style: label),
          Text('0', style: n(AppColors.red)),
        ]),
      ]),
    );
  }
}

class _OtherGrid extends StatelessWidget {
  const _OtherGrid();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.only(top: 30),
        decoration: cardDecoration(),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 23,
          childAspectRatio: 96 / 92,
          children: [
            for (final e in otherGrid)
              InkWell(
                onTap: () => openMenu(context, e.title),
                child: Column(children: [
                  Image.asset(img(e.icon), width: 32, height: 32, color: tintFor(e.title)),
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.4, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                ]),
              ),
          ],
        ),
      );
}
