import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF0F0F0);
  static const green = Color(0xFF4CAF50);
  static const red = Color(0xFFF44336);
  static const blue = Color(0xFF2196F3);
  static const orange = Color(0xFFFF9800);
  static const teal = Color(0xFF26A69A);
  static const darkTeal = Color(0xFF00695C);
  static const navy = Color(0xFF2B2D4F);
  static const slate = Color(0xFF3D4563);
  static const grey = Color(0xFF8E8E8E);
  static const chipGrey = Color(0xFFE3E3E3);
  static const lmsBlue = Color(0xFF5F95CF);
}

String img(String name) => 'assets/images/$name';

const double kRadius = 12;

BoxDecoration cardDecoration({double radius = kRadius, bool shadow = false}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow
          ? const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))]
          : null,
    );

/// Black app bar shared by every inner screen.
class BlackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BlackAppBar(this.title, {super.key, this.trailing, this.centerTitle = false, this.titleSize = 21});
  final double titleSize;
  final String title;
  final Widget? trailing;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) => AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.black,
        elevation: 4,
        shadowColor: Colors.black54,
        centerTitle: centerTitle,
        titleSpacing: 0,
        leadingWidth: 68,
        leading: IconButton(icon: const Icon(Icons.arrow_back, size: 25), onPressed: () => Navigator.of(context).maybePop()),
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: titleSize, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Colors.white)),
        actions: trailing == null ? null : [trailing!],
      );
}

/// Grey-track, green-fill attendance bar.
class PercentBar extends StatelessWidget {
  const PercentBar(this.percent, {super.key, this.track = const Color(0xFFDDDDDD)});
  final double percent;
  final Color track;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
            value: percent / 100, minHeight: 4.5, color: AppColors.green, backgroundColor: track),
      );
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, this.onChanged});
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        decoration: cardDecoration(radius: 8),
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14.2),
          textAlignVertical: const TextAlignVertical(y: -.4),
          decoration: const InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: AppColors.grey, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900, fontSize: 14.2),
            prefixIcon: Icon(Icons.search, color: AppColors.grey, size: 19),
            prefixIconConstraints: BoxConstraints(minWidth: 42),
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
}

/// Underlined text tabs used by Attendance, Mentoring and Transport.
class TextTabs extends StatelessWidget implements PreferredSizeWidget {
  const TextTabs({super.key, required this.tabs, this.scrollable = true});
  final List<Widget> tabs;
  final bool scrollable;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) => TabBar(
        padding: const EdgeInsets.only(left: 6),
        isScrollable: scrollable,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.navy,
        indicatorWeight: 2,
        labelColor: AppColors.navy,
        unselectedLabelColor: AppColors.grey,
        labelStyle: const TextStyle(fontSize: 18, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900),
        tabs: tabs,
      );
}

class SemChip extends StatelessWidget {
  const SemChip(this.sem, {super.key});
  final int sem;

  @override
  Widget build(BuildContext context) => Container(
        width: 55,
        height: 54,
        alignment: Alignment.center,
        decoration:
            BoxDecoration(color: AppColors.chipGrey, borderRadius: BorderRadius.circular(8)),
        child: Text('Sem\n$sem',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15.5, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400, color: Colors.black)),
      );
}

/// A.Y. label + highlighted academic year.
class YearLabel extends StatelessWidget {
  const YearLabel(this.year, {super.key, this.color = AppColors.teal, this.size = 14.5});
  final String year;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: [
        TextSpan(text: 'A.Y. ', style: TextStyle(color: AppColors.grey, fontSize: size, fontFamily: 'QuicksandMedium', fontWeight: FontWeight.w900)),
        TextSpan(text: year, style: TextStyle(color: color, fontSize: size, fontFamily: 'QuicksandBold', fontWeight: FontWeight.w400)),
      ]));
}

/// Original icons are single-colour PNGs tinted per menu item.
const _tints = <String, Color>{
  'Notifications': Color(0xFF9E9E9E), 'Attendance': Color(0xFF5C6BC0), 'Fees': Color(0xFF66BB6A),
  'Time Table': Color(0xFF42A5F5), 'Academic Calendar': Color(0xFF00BCD4), 'LMS Dashboard': Color(0xFFE57368),
  'Exam Schedule': Color(0xFF5E55C0), 'Circular': Color(0xFFF44336), 'Mentoring': Color(0xFF00695C),
  'Certificate Request': Color(0xFF42A5F5), 'Data Change Request': Color(0xFF26A69A), 'Announcement': Color(0xFF4A86C8),
  'Transport': Color(0xFFE6B800), 'Bus Finder': Color(0xFFF44336), 'Results': Color(0xFFE57368),
  'Feedback': Color(0xFF78909C), 'LMS Test Result': Color(0xFF26C6DA), 'Punishment': Color(0xFF00565B),
  'Hostel': Color(0xFF2ECC71), 'Grievance Registration': Color(0xFFEF5350), 'Term Registration': Color(0xFF00838F),
};
Color? tintFor(String title) => _tints[title];
