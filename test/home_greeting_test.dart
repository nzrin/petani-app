import 'package:flutter_test/flutter_test.dart';
import 'package:petani/home/utils/home_greeting.dart';

void main() {
  group('homeGreetingFor', () {
    test('uses the device-local morning greeting from 5:00 to 11:59', () {
      expect(homeGreetingFor(DateTime(2026, 9, 24, 5)), 'Selamat Pagi');
      expect(homeGreetingFor(DateTime(2026, 9, 24, 11, 59)), 'Selamat Pagi');
    });

    test('uses the midday greeting from 12:00 to 13:59', () {
      expect(homeGreetingFor(DateTime(2026, 9, 24, 12)), 'Selamat Tengah Hari');
      expect(
        homeGreetingFor(DateTime(2026, 9, 24, 13, 59)),
        'Selamat Tengah Hari',
      );
    });

    test('uses the afternoon greeting from 14:00 to 18:59', () {
      expect(homeGreetingFor(DateTime(2026, 9, 24, 14)), 'Selamat Petang');
      expect(homeGreetingFor(DateTime(2026, 9, 24, 18, 59)), 'Selamat Petang');
    });

    test('uses the night greeting from 19:00 to 4:59', () {
      expect(homeGreetingFor(DateTime(2026, 9, 24, 19)), 'Selamat Malam');
      expect(homeGreetingFor(DateTime(2026, 9, 25, 4, 59)), 'Selamat Malam');
    });
  });
}
