import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'common.dart';

/// Measured against the original screenshots:
/// heavy text is real Quicksand Bold; body text is Quicksand Medium with
/// synthetic bold applied on top (the original's single-face family + bold).
TextStyle hv(double size, [Color color = Colors.black]) =>
    TextStyle(fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, fontSize: size, color: color);

TextStyle bd(double size, [Color color = Colors.black]) =>
    TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, fontSize: size, color: color);

const kPageBg = Color(0xFFF0F0F0);
const kFieldBorder = Color(0xFF9E9E9E);
const kPillNavy = Color(0xFF0D1B8C);

/// The rich "Label*" used by outlined fields.
Widget _starLabel(String label) => Text.rich(TextSpan(children: [
      TextSpan(text: label, style: bd(12.5)),
      TextSpan(text: '*', style: bd(12.5, AppColors.red)),
    ]));

/// Outlined dropdown-looking field with a floating label.
class SelectField extends StatelessWidget {
  const SelectField({super.key, required this.label, required this.value, this.onTap, this.border = kFieldBorder});
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color border;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              height: 45,
              padding: const EdgeInsets.only(left: 16, right: 11),
              decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: border, width: 1), borderRadius: BorderRadius.circular(9)),
              child: Row(children: [
                Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.clip, softWrap: false, style: const TextStyle(fontFamily: 'QuicksandSemiBold', fontWeight: FontWeight.w400, fontSize: 15.4, color: Colors.black))),
                const Icon(Icons.arrow_drop_down, size: 24, color: Colors.black),
              ]),
            ),
            Positioned(
              left: 12,
              top: -8,
              child: Container(color: FieldLabelBg.of(context), padding: const EdgeInsets.symmetric(horizontal: 5), child: _starLabel(label)),
            ),
          ]),
        ),
      );
}

/// Supplies the colour behind floating field labels.
class FieldLabelBg extends InheritedWidget {
  const FieldLabelBg({super.key, required this.color, required super.child});
  final Color color;
  static Color of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<FieldLabelBg>()?.color ?? kPageBg;
  @override
  bool updateShouldNotify(FieldLabelBg old) => old.color != color;
}

/// Plain outlined text box with a hint ("Grievance Title*").
class HintBox extends StatelessWidget {
  const HintBox({super.key, required this.hint, this.height = 55, this.star = true, this.size = 18.4, this.top = false, this.color = const Color(0xFFD5D5D5), this.controller});
  final String hint;
  final double height;
  final bool star;
  final double size;
  final bool top;
  final Color color;

  /// When set, the box is editable and the hint disappears once there is text.
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final field = controller;
    final hintText = Text.rich(TextSpan(children: [
      TextSpan(text: hint, style: TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w400, fontSize: size, color: const Color(0xFF888888))),
      if (star) TextSpan(text: '*', style: TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w400, fontSize: size, color: AppColors.red)),
    ]));
    Widget box(Widget? child) => Container(
          height: height,
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, top ? 36 : 0, 12, 0),
          alignment: top ? Alignment.topLeft : Alignment.centerLeft,
          decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(9)),
          child: child,
        );
    if (field == null) return box(hintText);

    final tall = height > 60;
    return Stack(children: [
      ValueListenableBuilder(
        valueListenable: field,
        builder: (_, value, _) => box(value.text.isEmpty ? hintText : null),
      ),
      Positioned.fill(
        child: Semantics(
          label: hint,
          child: TextField(
            controller: field,
            maxLines: tall ? null : 1,
            expands: tall,
            textAlignVertical: tall ? TextAlignVertical.top : TextAlignVertical.center,
            style: TextStyle(fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w400, fontSize: size, color: Colors.black),
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.fromLTRB(20, tall ? 10 : 0, 12, tall ? 10 : 0),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// Dashed "Click to Upload or Capture Document" box.
class UploadBox extends StatelessWidget {
  const UploadBox({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashPainter(),
        child: SizedBox(
          height: 97,
          width: double.infinity,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.cloud_upload_outlined, color: Color(0xFF777777), size: 30),
            const SizedBox(height: 2),
            Text('Click to Upload or Capture Document', style: bd(13.7)),
            const SizedBox(height: 4),
            Text('( Max. File size:  1 MB )', style: bd(10.8, const Color(0xFF888888))),
          ]),
        ),
      );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF777777)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(9)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 4, m.length)), p);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cancel / Submit pair.
class FormButtons extends StatelessWidget {
  const FormButtons({super.key, this.height = 41, this.onSubmit, this.busy = false});
  final double height;

  /// Without this, Submit just closes the form.
  final VoidCallback? onSubmit;
  final bool busy;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 1.4), borderRadius: BorderRadius.circular(8)),
              child: Text('Cancel', style: const TextStyle(fontFamily: 'QuicksandSemiBold', fontWeight: FontWeight.w400, fontSize: 18.3, color: Colors.black)),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: GestureDetector(
            key: const Key('submit'),
            onTap: busy ? null : (onSubmit ?? () => Navigator.of(context).maybePop()),
            child: Container(
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: busy ? const Color(0xFF666666) : Colors.black, borderRadius: BorderRadius.circular(8)),
              child: Text(busy ? 'Submitting...' : 'Submit', style: const TextStyle(fontFamily: 'QuicksandSemiBold', fontWeight: FontWeight.w400, fontSize: 18.3, color: Colors.white)),
            ),
          ),
        ),
      ]);
}

const kSheetBg = Color(0xFFF0F0F0);

Widget _closeX(BuildContext c) => GestureDetector(
      onTap: () => Navigator.of(c).maybePop(),
      child: const CircleAvatar(radius: 11.5, backgroundColor: Color(0xFF1C1C1E), child: Icon(Icons.close, size: 13, color: Colors.white)),
    );

Widget _handle() => Center(
      child: Container(width: 56 / 1.1085, height: 3.5, margin: const EdgeInsets.only(top: 9), decoration: BoxDecoration(color: const Color(0xFFBDBDBD), borderRadius: BorderRadius.circular(2))),
    );

/// Bottom sheet shell shared by every picker and form.
Future<T?> showAppSheet<T>(BuildContext context, Widget Function(BuildContext) builder, {double? height, Color bg = Colors.white}) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: bg,
      barrierColor: const Color(0x8A000000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (c) => FieldLabelBg(
        color: bg,
        child: SizedBox(height: height, child: builder(c)),
      ),
    );

/// Searchable picker sheet.
void showPicker(BuildContext context, {required String title, required String hint, required List<String> items, bool firstSelected = true, String? selected, ValueChanged<String>? onSelected}) {
  showAppSheet<void>(context, height: 496, bg: kSheetBg, (c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _handle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 12),
          child: Row(children: [
            Expanded(child: Text(title, maxLines: 1, style: hv(21))),
            _closeX(c),
          ]),
        ),
        Container(
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.only(left: 9),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(border: Border.all(color: kFieldBorder), borderRadius: BorderRadius.circular(9)),
          child: Text(hint, style: bd(14.2, const Color(0xFF707070))),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final on = selected != null ? items[i] == selected : firstSelected && i == 0;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSelected == null
                    ? null
                    : () {
                        Navigator.of(c).pop();
                        onSelected(items[i]);
                      },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 54.2),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE3E3E3)))),
                  child: Row(children: [
                    Expanded(child: Text(items[i], style: on ? hv(13.8) : bd(13.5, const Color(0xFF333333)))),
                    if (on) const Icon(Icons.check_circle_outline, size: 18, color: AppColors.green),
                  ]),
                ),
              );
            },
          ),
        ),
      ]));
}

/// Title + close header for form sheets.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 11, 5, 8),
        child: Row(children: [
          Expanded(child: Text(title, maxLines: 1, style: hv(21))),
          _closeX(context),
        ]),
      );
}

Widget sheetHandle() => _handle();

/// Date chip with a calendar outline.
class DateChip extends StatelessWidget {
  const DateChip(this.text, {super.key, this.bg = const Color(0xFFF2F2F2), this.fg = const Color(0xFF666666), this.icon = 14, this.size = 11.1});
  final String text;
  final Color bg;
  final Color fg;
  final double icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today_outlined, size: icon, color: fg),
          const SizedBox(width: 5),
          Text(text, style: bd(size, fg)),
        ]),
      );
}

/// Grey empty-state message.
class EmptyText extends StatelessWidget {
  const EmptyText(this.text, {super.key, this.alignY = -.02});
  final String text;
  final double alignY;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment(0, alignY),
        child: Text(text, textAlign: TextAlign.center, style: hv(18, const Color(0xFF9E9E9E))),
      );
}

/// Pill selector with navy outline when active.
class OutlinePill extends StatelessWidget {
  const OutlinePill(this.text, {super.key, required this.on, this.onTap});
  final String text;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 31,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: on ? kPillNavy : const Color(0xFFAAAAAA), width: on ? 1.2 : 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text, style: bd(14.4, on ? kPillNavy : const Color(0xFF777777))),
        ),
      );
}

/// Tab label with a count bubble, shared by Results and Mentoring.
Widget countTab(String text, int n) => Tab(
      child: Row(children: [
        Text(text),
        const SizedBox(width: 9),
        CircleAvatar(radius: 11, backgroundColor: const Color(0xFF4A4F6A), child: Text('$n', style: bd(11, Colors.white))),
      ]),
    );
