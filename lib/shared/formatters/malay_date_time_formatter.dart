String formatMalayTime(DateTime value) {
  final localValue = value.toLocal();
  return formatMalayClockTime(hour: localValue.hour, minute: localValue.minute);
}

String formatMalayClockTime({required int hour, required int minute}) {
  final period = switch (hour) {
    < 12 => 'pagi',
    12 => 'tengah hari',
    < 19 => 'petang',
    _ => 'malam',
  };
  final displayHour = switch (hour) {
    0 => 12,
    > 12 => hour - 12,
    _ => hour,
  };
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}
