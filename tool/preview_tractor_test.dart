import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/shared/painters/isometric_tractor_painter.dart';

// Run with flutter test tool/preview_tractor_test.dart to inspect the Canvas art.
void main() {
  testWidgets('export tractor artwork for visual review', (tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xFFF7F5ED), BlendMode.src);
      const IsometricTractorPainter().paint(canvas, const Size(1000, 800));
      final picture = recorder.endRecording();
      final image = await picture.toImage(1000, 800);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '/private/tmp/petani-tractor-preview.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
      picture.dispose();

      if (const bool.fromEnvironment('TRACTOR_ANIMATION')) {
        final directory = Directory('/private/tmp/petani-tractor-frames')
          ..createSync(recursive: true);
        for (var frame = 0; frame < 60; frame++) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawColor(const Color(0xFFF7F5ED), BlendMode.src);
          IsometricTractorPainter(
            elapsedSeconds: frame / 15,
          ).paint(canvas, const Size(640, 640));
          final picture = recorder.endRecording();
          final image = await picture.toImage(640, 640);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${directory.path}/${frame.toString().padLeft(3, '0')}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
          picture.dispose();
        }
      }
    });
  });
}
