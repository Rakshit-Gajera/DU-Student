import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../async_view.dart';
import '../common.dart';
import '../format.dart';
import '../models/student_models.dart';
import '../providers/student_provider.dart';
import '../ui_kit.dart';

// ---------------------------------------------------------------- Calendar
class CalItem {
  const CalItem(this.date, this.title, this.done);
  final String date;
  final String title;
  final bool done;
}

const calItems = [
  CalItem('25-05-2026 To 15-06-2026', 'Term Registration', true),
  CalItem('08-06-2026', 'Commencement of Semester (Teaching)', true),
  CalItem('18-07-2026', 'Attendance Review - I', true),
  CalItem('29-08-2026', 'Attendance Review - II', true),
  CalItem('10-10-2026', 'Term End (Last Day of Teaching)', true),
  CalItem('12-10-2026 To 17-10-2026', 'Submission Of Term Work & SEE Practical Examination/Viva', true),
  CalItem('19-10-2026', 'Theory Semester End Examination (Tentative)', true),
  CalItem('07-12-2026', 'Commencement of Next Semester (Tentative)', false),
];

class AcademicCalendarScreen extends StatelessWidget {
  const AcademicCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const BlackAppBar('Academic Calendar'),
        body: ListView.builder(
          padding: const EdgeInsets.only(top: 9),
          itemCount: calItems.length,
          itemBuilder: (_, i) => SizedBox(height: calItems[i].title.length > 50 ? 99 : 81.4, child: _row(calItems[i], i)),
        ),
      );

  Widget _row(CalItem c, int i) => Row(children: [
        SizedBox(
          width: 46,
          child: Stack(alignment: Alignment.center, children: [
            Positioned(
              top: i == 0 ? 32 : 0,
              bottom: i == calItems.length - 1 ? 32 : 0,
              child: Container(width: 2.4, color: const Color(0xFFCDDCD6)),
            ),
            Positioned(
              left: 8.5,
              child: CircleAvatar(
                radius: 13.5,
                backgroundColor: c.done ? const Color(0xFFD0E0DB) : const Color(0xFFE0E0E0),
                child: c.done ? const Icon(Icons.check, size: 18, color: AppColors.darkTeal) : null,
              ),
            ),
          ]),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 15, top: 8, bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 3, 8, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFDDEAE6)),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              DateChip(c.date, bg: const Color(0xFFEAF2F0), fg: AppColors.darkTeal, size: 11.9),
              const SizedBox(height: 1),
              Text(c.title, maxLines: 2, style: bd(14).copyWith(height: 1.15)),
            ]),
          ),
        ),
      ]);
}

// ---------------------------------------------------------- Data change
const dcrTypes = [
  'Select Data Change Request Type',
  'I-Card Updation',
  "Student's Mobile Number",
  'Whatsapp Number',
  "Father's Mobile Number",
  "Mother's Mobile Number",
  'Address',
  "Student's Photo",
  'SSC Data',
  'HSC Data',
  'Graduation Data',
  'Aadhar Card Data',
  'Other',
];

class DataChangeScreen extends StatefulWidget {
  const DataChangeScreen({super.key});

  @override
  State<DataChangeScreen> createState() => _DataChangeScreenState();
}

class _DataChangeScreenState extends State<DataChangeScreen> {
  bool open = true;

  void _add() => showAppSheet<void>(context, (c) => Padding(
        padding: const EdgeInsets.fromLTRB(13, 0, 13, 7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          sheetHandle(),
          Padding(padding: const EdgeInsets.only(left: 4), child: const SheetTitle('Data Change Request')),
          SelectField(
            label: 'Data Change Request Type',
            value: 'Select Data Change Request Type',
            border: Colors.black,
            onTap: () => showPicker(c, title: 'Select Data Change Request Type', hint: 'Search Data Change Request Type', items: dcrTypes),
          ),
          const SizedBox(height: 10),
          const HintBox(hint: 'Request Description', height: 93, top: true),
          const SizedBox(height: 9),
          const UploadBox(),
          const SizedBox(height: 10),
          const FormButtons(),
        ]),
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BlackAppBar('Data Change Request', trailing: IconButton(key: const Key('add'), icon: const Icon(Icons.add, color: Colors.white, size: 27), onPressed: _add)),
        body: ListView(padding: const EdgeInsets.fromLTRB(7, 12, 7, 0), children: [
          Container(
            padding: const EdgeInsets.fromLTRB(11, 11, 11, 13),
            decoration: cardDecoration(radius: 5).copyWith(color: const Color(0xFFFBFBFB)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const DateChip('20-08-2024'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEAF5EA), borderRadius: BorderRadius.circular(4)),
                  child: Text('Approved', style: bd(12.3, AppColors.green)),
                ),
              ]),
              const SizedBox(height: 3),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text('I-Card Updation', style: hv(18))),
                GestureDetector(
                  onTap: () => setState(() => open = !open),
                  child: Container(
                    width: 27,
                    height: 27,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(5)),
                    child: Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 22, color: Colors.black87),
                  ),
                ),
              ]),
              if (open) ...[
                Text('Blood group = O+\nIt was not mentioned in the provisional I-Card.\nThankyou!', style: bd(13.6, const Color(0xFF888888)).copyWith(height: 1.25)),
                const SizedBox(height: 11),
                Text('Approved By Rakshit Gajera\non 21-08-2024 09:54 AM\nStatus Description : Update in your profile', style: bd(13.6, const Color(0xFF444444)).copyWith(height: 1.25)),
              ],
            ]),
          ),
        ]),
      );
}

// ---------------------------------------------------------------- Grievance
const grievanceTypes = [
  'Academics and Teaching-Learning',
  'Extra-curricular activities',
  'Internships and Placement',
  'Transportation Service',
  'Hostel Service',
  'Amenities & Maintenance',
  'General Administration',
  'Other',
];

class GrievanceScreen extends ConsumerStatefulWidget {
  const GrievanceScreen({super.key, this.expanded = false});
  final bool expanded;

  @override
  ConsumerState<GrievanceScreen> createState() => _GrievanceScreenState();
}

class _GrievanceScreenState extends ConsumerState<GrievanceScreen> {
  final Set<String> _toggled = {};
  String _query = '';
  String _filter = 'All';

  bool _matches(Grievance g) {
    final q = _query.toLowerCase();
    final found = g.title.toLowerCase().contains(q) || g.grievanceNo.toLowerCase().contains(q) || g.category.toLowerCase().contains(q);
    return found &&
        switch (_filter) {
          'Pending' => g.status != 'RESOLVED',
          'Completed' => g.status == 'RESOLVED',
          _ => true,
        };
  }

  /// Cards start as [GrievanceScreen.expanded] says; tapping one flips it.
  bool _isOpen(Grievance g) => _toggled.contains(g.id) != widget.expanded;

  void _add() => showAppSheet<void>(context, (_) => const _GrievanceForm());

  void _openFilter(BuildContext btn) {
    final top = MediaQuery.paddingOf(context).top + 56 + 7;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.transparent,
      pageBuilder: (c, _, _) => Stack(children: [
        Positioned(
          top: top,
          right: 15,
          width: 158,
          child: Material(
            color: Colors.white,
            elevation: 6,
            borderRadius: BorderRadius.circular(5),
            child: Column(children: [
              _opt(c, Colors.black, 'All'),
              _opt(c, AppColors.red, 'Pending'),
              _opt(c, AppColors.green, 'Completed'),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _opt(BuildContext dialog, Color c, String t) => GestureDetector(
        key: Key('filter-$t'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(dialog).pop();
          setState(() => _filter = t);
        },
        child: SizedBox(
          height: 45,
          child: Row(children: [
            const SizedBox(width: 15),
            SizedBox(width: 20, child: _filter == t ? const CircleAvatar(radius: 3.5, backgroundColor: Colors.black) : null),
            Text(t, style: bd(14.3, c)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BlackAppBar('Grievance', trailing: IconButton(key: const Key('add'), icon: const Icon(Icons.add, color: Colors.white, size: 27), onPressed: _add)),
        body: AsyncBody(
          value: ref.watch(grievancesProvider),
          onRetry: () => ref.invalidate(grievancesProvider),
          builder: (grievances) => ListView(padding: const EdgeInsets.fromLTRB(7, 9, 7, 8), children: [
            Row(children: [
              Expanded(child: SearchField(onChanged: (v) => setState(() => _query = v.trim()))),
              const SizedBox(width: 2),
              Builder(builder: (c) => SizedBox(width: 36, height: 34, child: IconButton(key: const Key('filter'), padding: EdgeInsets.zero, icon: const Icon(Icons.filter_list, size: 24, color: Colors.black87), onPressed: () => _openFilter(c)))),
            ]),
            const SizedBox(height: 11),
            for (final g in grievances)
              if (_matches(g)) _card(g),
          ]),
        ),
      );

  Widget _card(Grievance g) {
    final on = _isOpen(g);
    final resolved = g.status == 'RESOLVED';
    final resolvedAt = g.resolvedAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: cardDecoration(radius: 5).copyWith(color: const Color(0xFFFBFBFB)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          DateChip(istDate(g.filedAt)),
          const Spacer(),
          StatusBadge(g.status),
          const SizedBox(width: 6),
          const Icon(Icons.info_outline, size: 19, color: Colors.black87),
        ]),
        const SizedBox(height: 2),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.title, style: hv(18.3)),
              const SizedBox(height: 3),
              Text(g.category, style: bd(14.1, const Color(0xFF666666))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('(${g.grievanceNo})', style: bd(11.7, const Color(0xFF555555)).copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () => setState(() => _toggled.contains(g.id) ? _toggled.remove(g.id) : _toggled.add(g.id)),
              child: Container(
                width: 27,
                height: 27,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(color: on ? const Color(0xFFF0F0F0) : null, borderRadius: BorderRadius.circular(5)),
                child: Icon(on ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 22, color: Colors.black87),
              ),
            ),
          ]),
        ]),
        if (on) ...[
          const SizedBox(height: 7),
          _strip(const Color(0xFFF3F3F3), Row(children: [
            const Icon(Icons.tag, size: 14, color: Color(0xFF5F7A2B)),
            const SizedBox(width: 5),
            Text('Grievance No. :', style: bd(13.2, const Color(0xFF5F7A2B))),
            const SizedBox(width: 12),
            Text(g.grievanceNo, style: bd(13.2)),
          ])),
          const SizedBox(height: 5),
          _strip(const Color(0xFFFAF5EF), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _head(Icons.notes, 'Description', AppColors.orange),
            const SizedBox(height: 3),
            Text(g.description, style: bd(15.6).copyWith(height: 1.25)),
          ])),
          if (resolved && resolvedAt != null) ...[
            const SizedBox(height: 5),
            _strip(const Color(0xFFEEF3F3), Row(children: [
              const Icon(Icons.more_time, size: 14, color: AppColors.darkTeal),
              const SizedBox(width: 5),
              Text('Completed Time :', style: bd(13.2, AppColors.darkTeal)),
              const SizedBox(width: 12),
              Text(elapsed(g.filedAt, resolvedAt), style: bd(13.2)),
            ])),
            const SizedBox(height: 5),
            _strip(const Color(0xFFEEF3F3), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _head(Icons.notes, 'Status Description', AppColors.darkTeal),
              const SizedBox(height: 3),
              Text('By ${g.resolvedBy ?? '-'}\non ${istDateTime(resolvedAt)}\n${g.resolution ?? ''}', style: bd(12.4, const Color(0xFF222222)).copyWith(height: 1.2)),
            ])),
          ],
        ],
      ]),
    );
  }

  Widget _strip(Color c, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        color: c,
        child: child,
      );

  Widget _head(IconData i, String t, Color c) => Row(children: [
        Icon(i, size: 15, color: c),
        const SizedBox(width: 5),
        Text(t, style: bd(13.2, c)),
      ]);
}

class _GrievanceForm extends ConsumerStatefulWidget {
  const _GrievanceForm();

  @override
  ConsumerState<_GrievanceForm> createState() => _GrievanceFormState();
}

class _GrievanceFormState extends ConsumerState<_GrievanceForm> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _category;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final category = _category;
    if (category == null || _title.text.trim().isEmpty || _description.text.trim().isEmpty) {
      setState(() => _error = 'Fill in the type, title and description.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(studentRepoProvider).fileGrievance(category: category, title: _title.text.trim(), description: _description.text.trim());
      ref.invalidate(grievancesProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(13, 0, 13, 7 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          sheetHandle(),
          Padding(padding: const EdgeInsets.only(left: 4), child: const SheetTitle('Add Grievance Request')),
          SelectField(
            key: const Key('grievance-type'),
            label: 'Grievance Type',
            value: _category ?? 'Select Grievance Type',
            border: Colors.black,
            onTap: () => showPicker(context, title: 'Select Grievance Type', hint: 'Select Grievance Type', items: grievanceTypes, firstSelected: false, selected: _category, onSelected: (v) => setState(() => _category = v)),
          ),
          const SizedBox(height: 10),
          HintBox(key: const Key('grievance-title'), hint: 'Grievance Title', controller: _title),
          const SizedBox(height: 10),
          HintBox(key: const Key('grievance-description'), hint: 'Grievance Description', height: 93, top: false, controller: _description),
          const SizedBox(height: 13),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: UploadBox()),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, key: const Key('form-error'), style: bd(13.2, AppColors.red))),
          const SizedBox(height: 18),
          FormButtons(onSubmit: _submit, busy: _busy),
        ]),
      );
}

// --------------------------------------------------------------- Certificate
const certTypes = [
  'Select Certificate Type',
  'DU - Attempt / No Backlog Certificate (Charge Per Certificate: 100)',
  'DU - Bonafide Certificate',
  'DU - Certified Copy of Syllabus (Charge Per Certificate: 200)',
  'DU - Character Certificate (Charge Per Certificate: 100)',
  'DU - DIET - Fee Structure',
  'DU - English Proficiency Certificate (Charge Per Certificate: 100)',
];

class CertificateScreen extends ConsumerWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: BlackAppBar('Certificate Request',
            trailing: Row(children: [
              const Icon(Icons.filter_alt, color: Colors.white, size: 25),
              const SizedBox(width: 8),
              IconButton(
                key: const Key('add'),
                icon: const Icon(Icons.add, color: Colors.white, size: 27),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddCertificateScreen())),
              ),
            ])),
        body: AsyncBody(
          value: ref.watch(certificatesProvider),
          onRetry: () => ref.invalidate(certificatesProvider),
          builder: (requests) => requests.isEmpty
              ? const EmptyText('No any request found of certificate(s).', alignY: -.1)
              : ListView(padding: const EdgeInsets.fromLTRB(7, 9, 7, 8), children: [for (final r in requests) _card(r)]),
        ),
      );

  Widget _card(CertificateRequest r) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: cardDecoration(radius: 5).copyWith(color: const Color(0xFFFBFBFB)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            DateChip(istDate(r.requestedAt)),
            const Spacer(),
            StatusBadge(r.status),
          ]),
          const SizedBox(height: 4),
          Text(r.type, style: hv(16.5)),
          const SizedBox(height: 4),
          Text(
            [
              if (r.purpose != null) 'Purpose : ${r.purpose}',
              'No. of Copies : ${r.copies}',
              if (r.deliveryMode != null) 'Delivery Mode : ${r.deliveryMode}',
              if (r.details != null) 'Details : ${r.details}',
              if (r.remarks != null) 'Remarks : ${r.remarks}',
            ].join('\n'),
            style: bd(13.6, const Color(0xFF555555)).copyWith(height: 1.3),
          ),
        ]),
      );
}

const kCertBg = Color(0xFFF5F5F5);

class AddCertificateScreen extends ConsumerStatefulWidget {
  const AddCertificateScreen({super.key});

  @override
  ConsumerState<AddCertificateScreen> createState() => _AddCertificateScreenState();
}

class _AddCertificateScreenState extends ConsumerState<AddCertificateScreen> {
  final _details = TextEditingController();
  final _description = TextEditingController();
  String? _type;
  String? _purpose;
  String? _delivery;
  String _copies = '1';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _details.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final type = _type;
    if (type == null || _purpose == null || _delivery == null) {
      setState(() => _error = 'Select the certificate type, purpose and delivery mode.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final details = [_details.text.trim(), _description.text.trim()].where((t) => t.isNotEmpty).join('\n');
    try {
      await ref.read(studentRepoProvider).requestCertificate(
            type: type,
            purpose: _purpose,
            copies: int.parse(_copies),
            deliveryMode: _delivery,
            details: details.isEmpty ? null : details,
          );
      ref.invalidate(certificatesProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The placeholder rows at the top of these pickers mean "nothing chosen".
  void Function(String) _choose(void Function(String?) set) => (v) => setState(() => set(v.startsWith('Select ') ? null : v));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kCertBg,
        appBar: const BlackAppBar('Add Certificate Request'),
        body: FieldLabelBg(
          color: kCertBg,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(7, 9, 7, 9),
            child: Column(children: [
              SelectField(
                key: const Key('cert'),
                label: 'Certificate Type',
                value: _type ?? 'Select Certificate Type',
                border: const Color(0xFFD5D5D5),
                onTap: () => showPicker(context, title: 'Select Certificate Type', hint: 'Enter Certificate Type', items: certTypes, selected: _type, onSelected: _choose((v) => _type = v)),
              ),
              const SizedBox(height: 7),
              SelectField(
                key: const Key('purpose'),
                label: 'Purpose',
                value: _purpose ?? 'Select Purpose',
                border: const Color(0xFFD5D5D5),
                onTap: () => showPicker(context, title: 'Select Purpose', hint: 'Select Purpose', items: const ['Select Purpose', 'Other'], selected: _purpose, onSelected: _choose((v) => _purpose = v)),
              ),
              const SizedBox(height: 7),
              Row(children: [
                Expanded(
                  child: SelectField(
                    key: const Key('copies'),
                    label: 'No. of  Copies',
                    value: _copies,
                    border: const Color(0xFFD5D5D5),
                    onTap: () => showPicker(context, title: 'Select No. of  Copies', hint: 'Select No. of  Copies', items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'], selected: _copies, onSelected: (v) => setState(() => _copies = v)),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: SelectField(
                    key: const Key('delivery'),
                    label: 'Delivery Mode',
                    value: _delivery ?? 'Select Delivery Mode',
                    border: const Color(0xFFD5D5D5),
                    onTap: () => showPicker(context, title: 'Select Delivery Mode', hint: 'Select Delivery Mode', items: const ['Select Delivery Mode', 'In Person'], selected: _delivery, onSelected: _choose((v) => _delivery = v)),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              HintBox(key: const Key('cert-details'), hint: 'Certificate Details', star: false, size: 14.4, controller: _details),
              const SizedBox(height: 10),
              HintBox(key: const Key('cert-description'), hint: 'Description', star: false, size: 14.4, controller: _description),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, key: const Key('form-error'), style: bd(13.2, AppColors.red))),
              const Spacer(),
              FormButtons(onSubmit: _submit, busy: _busy),
            ]),
          ),
        ),
      );
}

// --------------------------------------------------------------- Simple screens
class CircularScreen extends ConsumerStatefulWidget {
  const CircularScreen({super.key});

  @override
  ConsumerState<CircularScreen> createState() => _CircularScreenState();
}

class _CircularScreenState extends ConsumerState<CircularScreen> {
  String _query = '';

  bool _matches(Circular c) => c.title.toLowerCase().contains(_query) || c.content.toLowerCase().contains(_query);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const BlackAppBar('Circular'),
        body: AsyncBody(
          value: ref.watch(circularsProvider),
          onRetry: () => ref.invalidate(circularsProvider),
          builder: (circulars) => Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(7, 7, 7, 0), child: SearchField(onChanged: (v) => setState(() => _query = v.trim().toLowerCase()))),
            Expanded(
              child: circulars.isEmpty
                  ? const EmptyText('No Recent Circulars', alignY: 0)
                  : ListView(padding: const EdgeInsets.fromLTRB(7, 9, 7, 8), children: [for (final c in circulars) if (_matches(c)) _card(c)]),
            ),
          ]),
        ),
      );

  Widget _card(Circular c) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: cardDecoration(radius: 5).copyWith(color: const Color(0xFFFBFBFB)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            DateChip(istDate(c.publishedAt)),
            const Spacer(),
            if (c.pinned) const Icon(Icons.push_pin, size: 17, color: AppColors.red),
          ]),
          const SizedBox(height: 4),
          Text(c.title, style: hv(16.5)),
          const SizedBox(height: 4),
          MarkdownBody(
            data: c.content,
            // Circulars are text. Do not fetch images from whatever URL a body names.
            imageBuilder: (_, _, alt) => Text(alt ?? '', style: bd(13.6, const Color(0xFF555555))),
            styleSheet: MarkdownStyleSheet(
              p: bd(13.6, const Color(0xFF333333)).copyWith(height: 1.3),
              strong: hv(13.6, const Color(0xFF111111)),
            ),
          ),
        ]),
      );
}

/// PENDING, RESOLVED and the other API statuses, as a small coloured label.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'RESOLVED' || 'APPROVED' => (const Color(0xFFEAF5EA), AppColors.green),
      'REJECTED' => (const Color(0xFFFDECEA), AppColors.red),
      _ => (const Color(0xFFFFF3E0), AppColors.orange),
    };
    final label = status.isEmpty ? status : status[0] + status.substring(1).toLowerCase().replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: bd(12.3, fg)),
    );
  }
}

/// One tab of the schedule screen.
class _ScheduleList extends ConsumerWidget {
  const _ScheduleList(this.type, {required this.empty});
  final ExamType type;
  final Widget empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = examScheduleProvider(type);
    return AsyncBody(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      builder: (entries) => entries.isEmpty
          ? empty
          : ListView(padding: const EdgeInsets.fromLTRB(7, 12, 7, 8), children: [for (final e in entries) _card(e)]),
    );
  }

  Widget _card(ExamEntry e) {
    final end = e.endDate;
    final details = [e.subjectName, e.venue].whereType<String>().join(' | ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: cardDecoration(radius: 5).copyWith(color: const Color(0xFFFBFBFB)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DateChip(end == null ? calendarDate(e.startDate) : '${calendarDate(e.startDate)} To ${calendarDate(end)}'),
        const SizedBox(height: 4),
        Text(e.title, style: hv(15.5)),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(details, style: bd(13.2, const Color(0xFF555555))),
        ],
      ]),
    );
  }
}

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        initialIndex: initialTab,
        child: Scaffold(
          appBar: const BlackAppBar('Schedule'),
          body: FieldLabelBg(
            color: kPageBg,
            child: Column(children: [
              const SizedBox(height: 6),
              const Align(alignment: Alignment.centerLeft, child: TextTabs(tabs: [Tab(text: 'Exam Schedule'), Tab(text: 'IA Schedule'), Tab(text: 'LMS Test Schedule')])),
              Expanded(
                child: TabBarView(children: [
                  const _ScheduleList(ExamType.exam, empty: EmptyText('No Data Found', alignY: -.03)),
                  Builder(builder: (c) => Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(19, 19, 19, 0),
                          child: SelectField(
                            label: 'Exam Result',
                            value: 'Select IA Schedule',
                            border: const Color(0xFF666666),
                            onTap: () => showPicker(c, title: 'Select IA Schedule', hint: 'Select IA Schedule', items: const ['Select IA Schedule']),
                          ),
                        ),
                        const Expanded(child: _ScheduleList(ExamType.ia, empty: EmptyText('No IA Schedule List Found', alignY: .0))),
                      ])),
                  const _ScheduleList(ExamType.lmsTest, empty: EmptyText('No Data Found', alignY: -.03)),
                ]),
              ),
            ]),
          ),
        ),
      );
}
