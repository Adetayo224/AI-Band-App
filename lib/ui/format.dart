/// Text formatting helpers (dates, times, durations, battery estimates).
class Fmt {
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// "Monday, 19 October"
  static String longDate(DateTime d) => '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

  static String greeting(DateTime d) {
    if (d.hour < 12) return 'Good morning';
    if (d.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// 24 hour clock, as used in Germany: "20:42".
  static String time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// "20:42", "Yesterday" or "Mon" for list rows.
  static String shortWhen(DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return time(d);
    if (_sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    if (now.difference(d).inDays < 7) return _short[d.weekday - 1];
    return '${d.day}.${d.month}.';
  }

  /// "Today, 20:42"
  static String dayAndTime(DateTime d) {
    final now = DateTime.now();
    final day = _sameDay(d, now)
        ? 'Today'
        : _sameDay(d, now.subtract(const Duration(days: 1)))
            ? 'Yesterday'
            : '${d.day} ${_months[d.month - 1]}';
    return '$day, ${time(d)}';
  }

  /// Group label for conversation lists.
  static String group(DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return 'Today';
    if (_sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return 'Earlier';
  }

  static String ago(DateTime d) {
    final m = DateTime.now().difference(d).inMinutes;
    if (m < 1) return 'just now';
    if (m < 60) return '$m min ago';
    final h = m ~/ 60;
    if (h < 24) return '$h h ago';
    return '${h ~/ 24} days ago';
  }

  /// "0:48"
  static String duration(int ms) {
    final s = (ms / 1000).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// Rough time left on battery. Assumes about 2.5 days from full; replace
  /// with measured figures once the hardware is tested.
  static String batteryLeft(int percent) {
    final hours = (percent / 100 * 60).round();
    if (hours >= 36) return 'About ${(hours / 24).round()} days left';
    if (hours >= 2) return 'About $hours hours left';
    return 'Charge soon';
  }

  /// Rough time to full charge. Assumes about 110 minutes from empty.
  static String chargeLeft(int percent) {
    if (percent >= 100) return 'Fully charged';
    final mins = ((100 - percent) / 100 * 110).round();
    if (mins < 60) return 'Full in about $mins min';
    return 'Full in about ${(mins / 60).toStringAsFixed(1)} h';
  }
}
