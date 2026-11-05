const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _pad(int v) => v.toString().padLeft(2, '0');

/// Calendar dates from the API ("2026-10-09", or midnight UTC for the same day)
/// have no time zone, so they are read as written and never converted.
DateTime _calendarDate(String iso) {
  final d = DateTime.parse(iso.substring(0, 10));
  return DateTime.utc(d.year, d.month, d.day);
}

/// "09-Oct-26", as in the attendance grid.
String gridDate(String iso) {
  final d = _calendarDate(iso);
  return '${_pad(d.day)}-${_months[d.month - 1]}-${_pad(d.year % 100)}';
}

/// "27-06-2026".
String calendarDate(String iso) {
  final d = _calendarDate(iso);
  return '${_pad(d.day)}-${_pad(d.month)}-${d.year}';
}

/// The university is in India, so date-times read the same on every device.
DateTime _ist(String iso) => DateTime.parse(iso).toUtc().add(const Duration(hours: 5, minutes: 30));

/// "05-12-2024".
String istDate(String iso) {
  final d = _ist(iso);
  return '${_pad(d.day)}-${_pad(d.month)}-${d.year}';
}

/// "18-03-2026 01:29 PM".
String istDateTime(String iso) {
  final d = _ist(iso);
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${istDate(iso)} ${_pad(hour)}:${_pad(d.minute)} ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "7 Days 7 Hours 10 Minutes".
String elapsed(String fromIso, String toIso) {
  final gap = DateTime.parse(toIso).difference(DateTime.parse(fromIso));
  return '${gap.inDays} Days ${gap.inHours % 24} Hours ${gap.inMinutes % 60} Minutes';
}

/// "Computer Science & Engineering" becomes "CSE".
String initials(String name) => name
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty && RegExp(r'^[A-Za-z]').hasMatch(w))
    .map((w) => w[0].toUpperCase())
    .join();
