String formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours > 0) return '${d.inHours}:$minutes:$seconds';
  return '$minutes:$seconds';
}

String formatSeconds(int seconds) => formatDuration(Duration(seconds: seconds));

String toPersianDigits(Object value) {
  const digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return value.toString().replaceAllMapped(RegExp(r'\d'), (m) => digits[int.parse(m[0]!)]);
}
