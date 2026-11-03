String homeGreetingFor(DateTime localTime) {
  final hour = localTime.hour;

  if (hour >= 5 && hour < 12) return 'Selamat Pagi';
  if (hour >= 12 && hour < 14) return 'Selamat Tengah Hari';
  if (hour >= 14 && hour < 19) return 'Selamat Petang';
  return 'Selamat Malam';
}
