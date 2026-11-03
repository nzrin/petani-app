import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A small orthographic Canvas scene, following MoneyStack's projected-surface
/// approach. All geometry is authored in tractor coordinates, then shaded and
/// painted back-to-front. No image, SVG, or animation asset is loaded.
class IsometricTractorPainter extends CustomPainter {
  const IsometricTractorPainter({this.animation, this.elapsedSeconds = 0})
    : super(repaint: animation);

  final ValueListenable<double>? animation;
  final double elapsedSeconds;

  // The mesh is immutable after construction and shared by all empty states.
  static final _scene = _buildTractor();

  /// Natural artwork proportions, from its highest point to the soil base.
  static double get aspectRatio => _scene._bounds.width / _scene._bounds.height;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _scene.paint(canvas, size, animation?.value ?? elapsedSeconds);
  }

  @override
  bool shouldRepaint(IsometricTractorPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.elapsedSeconds != elapsedSeconds;
}

const _green = Color(0xFF9EBB51);
const _greenLight = Color(0xFFC2D779);
const _greenDark = Color(0xFF6C8836);
const _red = Color(0xFFE84E3D);
const _redLight = Color(0xFFFF7150);
const _redDark = Color(0xFFA63232);
const _rubber = Color(0xFF3D3039);
const _rubberLight = Color(0xFF54404B);
const _metal = Color(0xFF55434B);
const _glass = Color(0xFF4C5350);
const _cream = Color(0xFFF6F1DC);

_TractorScene _buildTractor() {
  final s = _TractorScene();

  // Two rows of concave discs and a braced, red steel implement.
  for (final x in [-156.0, -105.0]) {
    for (var i = 0; i < 13; i++) {
      final y = -139.0 + i * 22;
      s.cylinder(
        x,
        y,
        18,
        radius: 18,
        width: 5,
        side: _metal,
        face: const Color(0xFF68505A),
      );
      s.disc(x, y + 5.4, 18, 7, _rubberLight);
      s.rotating(x, 18, 18, () {
        s.onSurface(x + y + 5.6 + 18 * .84, () {
          // Scalloped cutting edges and radial blades make the rotor's actual
          // axle rotation visible, even at the small empty-state size.
          s.face([
            for (var blade = 0; blade < 24; blade++)
              _V(
                x + math.cos(blade * math.pi / 12) * (blade.isEven ? 20 : 17),
                y + 5.6,
                18 + math.sin(blade * math.pi / 12) * (blade.isEven ? 20 : 17),
              ),
          ], const Color(0xFF6E5755));
          for (var blade = 0; blade < 5; blade++) {
            final a = blade * math.pi * 2 / 5;
            s.face([
              _V(x + math.cos(a) * 6, y + 5.9, 18 + math.sin(a) * 6),
              _V(
                x + math.cos(a + .2) * 17,
                y + 5.9,
                18 + math.sin(a + .2) * 17,
              ),
              _V(
                x + math.cos(a + .45) * 16,
                y + 5.9,
                18 + math.sin(a + .45) * 16,
              ),
            ], const Color(0xFFAA8A75));
          }
          s.disc(x, y + 6, 18, 4.5, _metal);
        });
      });
    }
    s.box(x - 4, -153, 32, x + 4, 153, 41, _red);
    s.box(x - 3, -144, 24, x + 3, 144, 30, _redDark);
  }
  for (final y in [-149.0, -75.0, 0.0, 75.0, 149.0]) {
    s.box(-164, y - 4, 40, -97, y + 4, 48, _red);
  }
  s.beam(const _V(-156, -143, 46), const _V(-105, 0, 46), 5, _redLight);
  s.beam(const _V(-156, 143, 46), const _V(-105, 0, 46), 5, _redLight);
  s.beam(const _V(-105, -75, 43), const _V(-43, 0, 39), 5, _red);
  s.beam(const _V(-105, 75, 43), const _V(-43, 0, 39), 5, _red);
  s.box(-48, -6, 33, -5, 6, 42, _metal);
  for (final y in [-150.0, 150.0]) {
    s.beam(_V(-156, y, 44), _V(-156, y, 74), 1.6, _metal);
    s.face([
      _V(-157, y - 10, 69),
      _V(-157, y + 10, 69),
      _V(-157, y + 10, 88),
      _V(-157, y - 10, 88),
    ], _cream);
    for (var i = 0; i < 3; i++) {
      final z = 70.0 + i * 6;
      s.face([
        _V(-156.5, y - 10, z),
        _V(-156.5, y + 10, z + 8),
        _V(-156.5, y + 10, z + 12),
        _V(-156.5, y - 10, z + 4),
      ], _redDark);
    }
  }

  // Chassis, axles and four independently modelled tires.
  s.box(-22, -35, 43, 223, 35, 64, _metal);
  s.box(-5, -76, 51, 18, 76, 66, _metal);
  s.box(170, -71, 36, 188, 71, 48, _metal);
  for (final near in [false, true]) {
    final rearGuard = _fender(s, 10, near ? 51 : -89, 63, 68, 39, _green);
    final frontGuard = _fender(
      s,
      186,
      near ? 49 : -80,
      44,
      49,
      31,
      _rubberLight,
      from: .30,
      to: math.pi - .30,
    );
    s.occludedBy(rearGuard, () {
      _wheel(s, x: 10, y: near ? 56 : -83, z: 63, radius: 61, width: 29);
    });
    s.occludedBy(frontGuard, () {
      _wheel(s, x: 186, y: near ? 51 : -75, z: 44, radius: 42, width: 25);
    });
  }

  // Engine cowling: a sloped bonnet with a narrow nose and shaded side panels.
  s.face([
    const _V(81, -36, 127),
    const _V(81, 36, 127),
    const _V(222, 30, 104),
    const _V(222, -30, 104),
  ], _greenLight);
  s.face([
    const _V(81, 36, 127),
    const _V(222, 30, 104),
    const _V(226, 32, 61),
    const _V(85, 39, 65),
  ], _green);
  s.face([
    const _V(81, -36, 127),
    const _V(222, -30, 104),
    const _V(226, -32, 61),
    const _V(85, -39, 65),
  ], _greenDark);
  s.face([
    const _V(88, 39.4, 103),
    const _V(122, 38, 96),
    const _V(119, 38.6, 73),
    const _V(90, 39.5, 72),
  ], _greenDark);
  s.line(
    [const _V(83, 36.4, 126), const _V(221, 30.5, 103)],
    const Color(0xFFD7E59C),
    1.3,
  );
  // Grille and a pair of inset warm-white headlamps.
  s.face([
    const _V(224, -29, 101),
    const _V(224, 29, 101),
    const _V(228, 29, 57),
    const _V(228, -29, 57),
  ], _rubber);
  s.onSurface(293, () {
    for (var y = -23.0; y <= 23; y += 5.8) {
      s.line([_V(225, y, 92), _V(228.4, y, 62)], const Color(0xFF6B5860), 1.6);
    }
    for (final y in [-27.0, 15.0]) {
      s.face([
        _V(225, y, 101),
        _V(225, y + 12, 101),
        _V(226, y + 12, 94),
        _V(226, y, 94),
      ], _cream);
    }
  });
  s.box(228, -36, 27, 251, 36, 46, _green);
  s.box(247, -32, 31, 253, 32, 42, _greenDark);
  s.line([const _V(253.3, 18, 37), const _V(253.3, 29, 37)], _metal, 2);

  // Cab shell and glazing. The front screen leans back toward the cream roof.
  s.box(-20, -42, 72, 84, 42, 111, _metal);
  s.face([
    const _V(-19, 43, 109),
    const _V(83, 43, 109),
    const _V(67, 43, 180),
    const _V(-16, 43, 180),
  ], _glass);
  s.face([
    const _V(83, -42, 109),
    const _V(83, 42, 109),
    const _V(67, 42, 180),
    const _V(67, -42, 180),
  ], const Color(0xFF36453F));
  s.face([
    const _V(-20, -42, 109),
    const _V(-16, -42, 180),
    const _V(67, -42, 180),
    const _V(83, -42, 109),
  ], _glass);
  s.onSurface(199, () {
    // Reflections are clipped polygons on the window planes.
    s.face([
      const _V(-10, 43.5, 174),
      const _V(18, 43.5, 174),
      const _V(53, 43.5, 115),
      const _V(39, 43.5, 115),
    ], const Color(0xFF6B7870));
    s.face([
      const _V(68.3, -31, 175),
      const _V(68.3, -19, 175),
      const _V(81, 11, 119),
      const _V(81, 2, 119),
    ], const Color(0xFF78836A));
  });
  // Door seals, pillars, window divider and handles.
  for (final y in [-44.0, 44.0]) {
    s.onSurface(y > 0 ? 194 : 108, () {
      s.beam(_V(-18, y, 107), _V(-16, y, 183), 3, _metal);
    });
    s.beam(_V(84, y, 107), _V(68, y, 183), 3.6, _metal);
    s.onSurface(y > 0 ? 194 : 108, () {
      s.beam(_V(27, y, 108), _V(27, y, 182), 2.3, _metal);
    });
    s.line([_V(-16, y, 109), _V(83, y, 109)], _metal, 4);
  }
  s.beam(const _V(69, -44, 181), const _V(69, 44, 181), 3, _metal);
  s.line([const _V(49, 45, 128), const _V(60, 45, 128)], _rubber, 3);
  s.line([const _V(82.5, 19, 117), const _V(70, -4, 167)], _rubber, 2);
  s.onSurface(194, () {
    // A dark seat silhouette visible through the side glass.
    s.face([
      const _V(0, 44, 124),
      const _V(17, 44, 124),
      const _V(15, 44, 149),
      const _V(0, 44, 149),
    ], const Color(0xFF3E4642));
  });
  // Overhanging ivory roof and its recessed skylight.
  s.onSurface(280, () {
    s.box(-27, -55, 183, 88, 55, 191, _cream);
    s.face([
      const _V(1, -23, 191.2),
      const _V(1, 13, 191.2),
      const _V(38, 13, 191.2),
      const _V(38, -23, 191.2),
    ], const Color(0xFFC9C7B4));
    s.face([
      const _V(5, -19, 191.5),
      const _V(5, 9, 191.5),
      const _V(34, 9, 191.5),
      const _V(34, -19, 191.5),
    ], const Color(0xFF666B60));
    s.face([
      const _V(6, -17, 191.6),
      const _V(6, -8, 191.6),
      const _V(33, 7, 191.6),
      const _V(33, -3, 191.6),
    ], const Color(0xFF899184));
  });
  // Steps and the tall exhaust are in front of the near-side cab.
  for (var i = 0; i < 3; i++) {
    final z = 24.0 + i * 15;
    s.box(55, 43, z, 86, 64 - i * 3, z + 6, _metal);
    for (var x = 59.0; x < 84; x += 6) {
      s.line(
        [_V(x, 46, z + 6.2), _V(x, 60 - i * 3, z + 6.2)],
        const Color(0xFF89716F),
        1.2,
      );
    }
  }
  s.box(80, 44, 20, 86, 59, 76, _metal);
  s.box(94, 38, 79, 106, 51, 130, _metal);
  s.box(97, 40, 130, 103, 47, 163, _rubber);
  s.beam(const _V(100, 43.5, 163), const _V(107, 43.5, 169), 3.5, _rubber);
  // Side mirrors and amber roof beacons.
  for (final y in [-1.0, 1.0]) {
    s.line(
      [_V(62, y * 47, 174), _V(69, y * 70, 174), _V(69, y * 73, 153)],
      _metal,
      2.6,
    );
    s.box(65, y > 0 ? 70 : -77, 143, 73, y > 0 ? 77 : -70, 163, _metal);
    s.box(
      73.3,
      y > 0 ? 71 : -76,
      146,
      74,
      y > 0 ? 76 : -71,
      160,
      const Color(0xFF82918A),
    );
    s.onSurface(281, () {
      s.box(70, y * 48 - 4, 191, 78, y * 48 + 4, 194, _metal);
      s.box(71, y * 48 - 3, 194, 77, y * 48 + 3, 205, const Color(0xFFF4AF32));
      s.line(
        [_V(72, y * 48 + 3.3, 196), _V(72, y * 48 + 3.3, 203)],
        const Color(0xFFFFD66F),
        1.5,
      );
    });
  }
  s.finish();
  return s;
}

void _wheel(
  _TractorScene s, {
  required double x,
  required double y,
  required double z,
  required double radius,
  required double width,
}) {
  s.wobbling(x, y + width / 2, z, () {
    s.cylinder(
      x,
      y,
      z,
      radius: radius,
      width: width,
      side: _rubber,
      face: _rubberLight,
      bevel: 4,
    );
    s.rotating(x, z, radius, () {
      // Raised chevron tread blocks wrap around the tire, including its shoulders.
      const count = 20;
      for (var i = 0; i < count; i++) {
        final a = i * math.pi * 2 / count;
        for (final half in [0, 1]) {
          final y0 = y + (half == 0 ? 1 : width / 2);
          final y1 = y + (half == 0 ? width / 2 : width - 1);
          final skew = half == 0 ? .13 : -.13;
          _V p(double angle, double axis, double r) =>
              _V(x + math.cos(angle) * r, axis, z + math.sin(angle) * r);
          final corners = [
            p(a, y0, radius + 1.7),
            p(a + .11, y0, radius + 1.7),
            p(a + .11 + skew, y1, radius + 1.7),
            p(a + skew, y1, radius + 1.7),
          ];
          s.face(
            corners,
            Color.lerp(_rubber, _rubberLight, .4 + .2 * math.sin(a))!,
          );
          s.face([
            corners[0],
            corners[3],
            p(a + skew, y1, radius - .8),
            p(a, y0, radius - .8),
          ], _rubber);
        }
      }
    });
    final outward = y + width + .3;
    s.onSurface(x + outward + z * .84 + 1, () {
      s.disc(x, outward, z, radius * .74, const Color(0xFF604850));
      s.disc(x, outward + .2, z, radius * .51, _redLight);
      s.disc(x, outward + .4, z, radius * .44, _redDark);
      s.disc(x, outward + .6, z, radius * .39, _red);
      s.rotating(x, z, radius, () {
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          s.disc(
            x + math.cos(a) * radius * .31,
            outward + .9,
            z + math.sin(a) * radius * .31,
            radius * .048,
            _metal,
          );
        }
      });
      s.cylinder(
        x,
        outward + 1,
        z,
        radius: radius * .16,
        width: 4,
        side: _redDark,
        face: _metal,
      );
    });
  });
}

Path _fender(
  _TractorScene s,
  double x,
  double y,
  double z,
  double radius,
  double width,
  Color color, {
  double from = .10,
  double to = math.pi - .10,
}) {
  var silhouette = Path();
  void panel(List<_V> points, Color shade) {
    s.face(points, shade);
    silhouette = Path.combine(
      PathOperation.union,
      silhouette,
      Path()..addPolygon(points.map((p) => p.projected).toList(), true),
    );
  }

  for (var i = 0; i < 20; i++) {
    final a = from + (to - from) * i / 20;
    final b = from + (to - from) * (i + 1) / 20;
    _V p(double angle, double axis, double r) =>
        _V(x + math.cos(angle) * r, axis, z + math.sin(angle) * r);
    panel([
      p(a, y, radius),
      p(a, y + width, radius),
      p(b, y + width, radius),
      p(b, y, radius),
    ], color);
    panel([
      p(a, y + width, radius),
      p(a, y + width, radius - 5),
      p(b, y + width, radius - 5),
      p(b, y + width, radius),
    ], Color.lerp(color, Colors.black, .15)!);
  }
  return silhouette;
}

const _soilHalfExtent = 265.0;
const _soilThickness = 30.0;
final _soilPath = Path()
  ..addPolygon([
    for (final corner in const [
      _V(25 - _soilHalfExtent, -_soilHalfExtent, 0),
      _V(25 + _soilHalfExtent, -_soilHalfExtent, 0),
      _V(25 + _soilHalfExtent, _soilHalfExtent, 0),
      _V(25 - _soilHalfExtent, _soilHalfExtent, 0),
    ])
      corner.projected,
  ], true);
final _soilBounds = _soilPath.getBounds();

void _paintSoil(Canvas canvas, double distance, double seconds) {
  Path polygon(List<_V> points) =>
      Path()..addPolygon(points.map((p) => p.projected).toList(), true);
  void fill(List<_V> points, Color color) =>
      canvas.drawPath(polygon(points), Paint()..color = color);
  // Exposed earth on the two camera-facing sides gives the tile depth.
  const left = 25 - _soilHalfExtent;
  const right = 25 + _soilHalfExtent;
  fill([
    const _V(right, -_soilHalfExtent, 0),
    const _V(right, _soilHalfExtent, 0),
    const _V(right, _soilHalfExtent, -_soilThickness),
    const _V(right, -_soilHalfExtent, -_soilThickness),
  ], const Color(0xFF795237));
  fill([
    const _V(left, _soilHalfExtent, 0),
    const _V(right, _soilHalfExtent, 0),
    const _V(right, _soilHalfExtent, -_soilThickness),
    const _V(left, _soilHalfExtent, -_soilThickness),
  ], const Color(0xFF946740));
  final top = _soilPath;
  canvas.drawPath(
    top,
    Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFC8A372), Color(0xFFB18756)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(top.getBounds()),
  );

  canvas.save();
  canvas.clipPath(top);
  // Freshly worked earth stays behind the implement; the moving ground
  // texture passes through it continuously without moving the patch.
  fill([
    const _V(-275, -153, 0),
    const _V(-112, -153, 0),
    const _V(-100, -123, 0),
    const _V(-111, -90, 0),
    const _V(-101, -50, 0),
    const _V(-109, 0, 0),
    const _V(-102, 50, 0),
    const _V(-111, 105, 0),
    const _V(-104, 153, 0),
    const _V(-275, 153, 0),
  ], const Color(0xFF775038));
  for (var row = 0; row < 16; row++) {
    final y = -145.0 + row * 19;
    final points = <Offset>[];
    for (var x = -280.0; x <= -108; x += 5) {
      points.add(
        _V(x, y + math.sin((x + distance) * .085 + row) * 1.5, .1).projected,
      );
    }
    canvas.drawPath(
      Path()..addPolygon(points, false),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = row.isEven
            ? const Color(0xFFA1764D)
            : const Color(0xFF583D2C),
    );
  }
  // Repeating grains stream backward at exactly the tires' linear speed.
  for (var i = 0; i < 150; i++) {
    final x =
        25 - _soilHalfExtent + ((i * 67.3 - distance) % (2 * _soilHalfExtent));
    final y = -_soilHalfExtent + (i * 97.7) % (2 * _soilHalfExtent);
    final tilled = x < -107 && y.abs() < 153;
    final radius = 1.5 + i % 4;
    final color = tilled
        ? (i.isEven ? const Color(0xFFBA8B59) : const Color(0xFF513926))
        : (i.isEven ? const Color(0xFFD7B786) : const Color(0xFF9C744C));
    fill([
      _V(x - radius, y, 0),
      _V(x, y - radius * .65, 0),
      _V(x + radius, y, 0),
      _V(x, y + radius * .65, 0),
    ], color);
  }
  // Tire impressions vanish as the rear implement breaks up the earth.
  for (final y in [-68.0, 68.0]) {
    for (var i = 0; i < 18; i++) {
      final x = -95 + ((i * 16.0 - distance) % 280);
      canvas.drawPath(
        Path()..addPolygon([
          _V(x - 3, y - 10, 0).projected,
          _V(x + 1, y, 0).projected,
          _V(x - 3, y + 10, 0).projected,
        ], false),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0x5585603C),
      );
    }
  }
  canvas.restore();

  // Small, staggered clods follow a low arc behind the working rotor.
  for (var i = 0; i < 14; i++) {
    final phase = (seconds * .9 + i * .173) % 1;
    final x = -160 - phase * 65;
    final y = -139 + i * 21.0;
    final z = 2 + math.sin(phase * math.pi) * (12 + i % 4 * 3);
    final r = (2.3 + i % 3) * (1 - phase * .35);
    fill(
      [
        _V(x - r, y, z),
        _V(x, y - r, z + 2),
        _V(x + r, y, z),
        _V(x, y + r, z - 1),
      ],
      Color.lerp(
        const Color(0xFF67412D),
        const Color(0xFFAC7D4B),
        i / 14,
      )!.withValues(alpha: 1 - phase * .7),
    );
  }
}

class _V {
  const _V(this.x, this.y, this.z);
  final double x, y, z;
  Offset get projected => Offset((x - y) * .82, (x + y) * .42 - z);
  double get depth => x + y + z * .84;
}

class _Axle {
  const _Axle(this.x, this.z, this.radius);
  final double x, z, radius;

  _V rotate(_V p, double distance) {
    // Forward travel is +X; the contact patch moves backward relative to
    // the axle. Both tire sizes therefore share the same ground speed.
    final angle = -distance / radius;
    final c = math.cos(angle), s = math.sin(angle);
    final dx = p.x - x, dz = p.z - z;
    return _V(x + dx * c - dz * s, p.y, z + dx * s + dz * c);
  }
}

class _WheelWobble {
  const _WheelWobble(this.center, this.phase);
  final Offset center;
  final double phase;

  void apply(Canvas canvas, double seconds) {
    // Each tire reacts independently to bumps while the chassis stays steady.
    final bounce =
        math.sin(seconds * 5.8 + phase) * 2.2 +
        math.sin(seconds * 13.1 + phase * 2) * .7;
    final sway = math.sin(seconds * 3.1 + phase) * .8;
    final rock = math.sin(seconds * 4.3 + phase) * .018;
    canvas.translate(center.dx + sway, center.dy + bounce);
    canvas.rotate(rock);
    canvas.translate(-center.dx, -center.dy);
  }
}

class _Surface {
  _Surface(
    this.vertices,
    this.color,
    this.order, {
    this.strokeWidth,
    this.minimumDepth,
    this.axle,
    this.visibleRegion,
    this.wobble,
  });
  final List<_V> vertices;
  final Color color;
  final int order;
  final double? strokeWidth;
  final double? minimumDepth;
  final _Axle? axle;
  final Path? visibleRegion;
  final _WheelWobble? wobble;

  _Surface at(double distance) => _Surface(
    vertices.map((p) => axle!.rotate(p, distance)).toList(),
    color,
    order,
    strokeWidth: strokeWidth,
    minimumDepth: minimumDepth,
    visibleRegion: visibleRegion,
    wobble: wobble,
  );
  late final depth = math.max(
    minimumDepth ?? double.negativeInfinity,
    vertices.fold<double>(0, (n, p) => n + p.depth) / vertices.length,
  );
  late final path = Path()
    ..addPolygon(
      vertices.map((p) => p.projected).toList(),
      strokeWidth == null,
    );
}

class _TractorScene {
  final _surfaces = <_Surface>[];
  late final List<_Surface> _stationary;
  late final List<_Surface> _rotating;
  late final Rect _bounds;
  double? _minimumDepth;
  _Axle? _axle;
  Path? _visibleRegion;
  _WheelWobble? _wobble;

  void wobbling(double x, double y, double z, VoidCallback draw) {
    final previous = _wobble;
    _wobble = _WheelWobble(_V(x, y, z).projected, x * .017 + y * .023);
    draw();
    _wobble = previous;
  }

  // Average face depth cannot reliably order a curved tire against its guard.
  // Their projected overlap always belongs to the guard, even as treads turn.
  void occludedBy(Path silhouette, VoidCallback draw) {
    final previous = _visibleRegion;
    _visibleRegion = Path.combine(
      PathOperation.difference,
      Path()..addRect(_soilBounds.inflate(_soilHalfExtent)),
      silhouette,
    );
    draw();
    _visibleRegion = previous;
  }

  void rotating(double x, double z, double radius, VoidCallback draw) {
    final previous = _axle;
    _axle = _Axle(x, z, radius);
    draw();
    _axle = previous;
  }

  /// Keep coplanar decoration above the larger surface that owns it.
  void onSurface(double depth, VoidCallback draw) {
    final previous = _minimumDepth;
    _minimumDepth = depth;
    draw();
    _minimumDepth = previous;
  }

  void face(List<_V> points, Color color) => _surfaces.add(
    _Surface(
      points,
      color,
      _surfaces.length,
      minimumDepth: _minimumDepth,
      axle: _axle,
      visibleRegion: _visibleRegion,
      wobble: _wobble,
    ),
  );

  void line(List<_V> points, Color color, double width) => _surfaces.add(
    _Surface(
      points,
      color,
      _surfaces.length,
      strokeWidth: width,
      minimumDepth: _minimumDepth,
      axle: _axle,
      visibleRegion: _visibleRegion,
      wobble: _wobble,
    ),
  );

  void box(
    double x0,
    double y0,
    double z0,
    double x1,
    double y1,
    double z1,
    Color color,
  ) {
    face([
      _V(x0, y0, z1),
      _V(x1, y0, z1),
      _V(x1, y1, z1),
      _V(x0, y1, z1),
    ], Color.lerp(color, Colors.white, .16)!);
    face([
      _V(x1, y0, z0),
      _V(x1, y1, z0),
      _V(x1, y1, z1),
      _V(x1, y0, z1),
    ], Color.lerp(color, Colors.black, .18)!);
    face([
      _V(x0, y1, z0),
      _V(x1, y1, z0),
      _V(x1, y1, z1),
      _V(x0, y1, z1),
    ], color);
  }

  void beam(_V a, _V b, double thickness, Color color) {
    // A square beam, including its shaded lower edge.
    line(
      [_V(a.x, a.y, a.z - thickness / 2), _V(b.x, b.y, b.z - thickness / 2)],
      Color.lerp(color, Colors.black, .2)!,
      thickness * 2,
    );
    line([a, b], color, thickness * 1.5);
  }

  void disc(double x, double y, double z, double radius, Color color) {
    face([
      for (var i = 0; i < 48; i++)
        _V(
          x + math.cos(i * math.pi / 24) * radius,
          y,
          z + math.sin(i * math.pi / 24) * radius,
        ),
    ], color);
  }

  void cylinder(
    double x,
    double y,
    double z, {
    required double radius,
    required double width,
    required Color side,
    required Color face,
    double bevel = 1,
  }) {
    final rings = [
      (y, radius - bevel),
      (y + bevel, radius),
      (y + width - bevel, radius),
      (y + width, radius - bevel),
    ];
    for (var j = 0; j < rings.length - 1; j++) {
      for (var i = 0; i < 40; i++) {
        final a = i * math.pi / 20;
        final b = (i + 1) * math.pi / 20;
        final (y0, r0) = rings[j];
        final (y1, r1) = rings[j + 1];
        final light = (.5 + math.sin(a) * .5) * .14;
        this.face([
          _V(x + math.cos(a) * r0, y0, z + math.sin(a) * r0),
          _V(x + math.cos(b) * r0, y0, z + math.sin(b) * r0),
          _V(x + math.cos(b) * r1, y1, z + math.sin(b) * r1),
          _V(x + math.cos(a) * r1, y1, z + math.sin(a) * r1),
        ], Color.lerp(side, Colors.white, light)!);
      }
    }
    disc(x, y + width, z, radius - bevel, face);
  }

  void finish() {
    _surfaces.sort((a, b) {
      final depth = a.depth.compareTo(b.depth);
      return depth == 0 ? a.order.compareTo(b.order) : depth;
    });
    _stationary = _surfaces.where((s) => s.axle == null).toList();
    _rotating = _surfaces.where((s) => s.axle != null).toList();
    final points = _surfaces.expand((s) => s.vertices).map((p) => p.projected);
    var left = double.infinity, top = double.infinity;
    var right = double.negativeInfinity, bottom = double.negativeInfinity;
    for (final p in points) {
      left = math.min(left, p.dx);
      top = math.min(top, p.dy);
      right = math.max(right, p.dx);
      bottom = math.max(bottom, p.dy);
    }
    // The soil patch fixes the frame, independent of wheel rotation.
    left = math.min(left, _soilBounds.left);
    top = math.min(top, _soilBounds.top);
    right = math.max(right, _soilBounds.right);
    bottom = math.max(bottom, _soilBounds.bottom + _soilThickness);
    // Only a small antialiasing margin; layout follows the visible artwork.
    _bounds = Rect.fromLTRB(left - 2, top - 2, right + 2, bottom + 2);
  }

  void paint(Canvas canvas, Size size, double seconds) {
    final motionSeconds = seconds * 1.89;
    final distance = motionSeconds * 36;
    final scale = math.min(
      size.width / _bounds.width,
      size.height / _bounds.height,
    );
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-_bounds.center.dx, -_bounds.center.dy);
    _paintSoil(canvas, distance, motionSeconds);
    canvas.save();
    canvas.clipPath(_soilPath);
    final shadow = Path()
      ..addPolygon(
        [
          const _V(-173, -158, 0),
          const _V(-173, 158, 0),
          const _V(-85, 158, 0),
          const _V(-32, 90, 0),
          const _V(248, 83, 0),
          const _V(270, -67, 0),
          const _V(10, -84, 0),
          const _V(-88, -155, 0),
        ].map((p) => p.projected + const Offset(12, 8)).toList(),
        true,
      );
    canvas.drawPath(
      shadow,
      Paint()
        ..color = const Color(0x453C261B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.restore();
    final paint = Paint()..isAntiAlias = true;
    final moving = _rotating.map((s) => s.at(distance)).toList()
      ..sort((a, b) {
        final depth = a.depth.compareTo(b.depth);
        return depth == 0 ? a.order.compareTo(b.order) : depth;
      });
    // Merge moving geometry with the cached stationary mesh in depth order.
    var fixedIndex = 0, movingIndex = 0;
    while (fixedIndex < _stationary.length || movingIndex < moving.length) {
      final useFixed =
          movingIndex == moving.length ||
          (fixedIndex < _stationary.length &&
              _stationary[fixedIndex].depth <= moving[movingIndex].depth);
      final surface = useFixed
          ? _stationary[fixedIndex++]
          : moving[movingIndex++];
      final needsTransform =
          surface.visibleRegion != null || surface.wobble != null;
      if (needsTransform) canvas.save();
      // Clip in the stationary guard's coordinates before moving the tire.
      if (surface.visibleRegion != null) {
        canvas.clipPath(surface.visibleRegion!);
      }
      surface.wobble?.apply(canvas, motionSeconds);
      paint
        ..color = surface.color
        ..style = surface.strokeWidth == null
            ? PaintingStyle.fill
            : PaintingStyle.stroke
        ..strokeWidth = surface.strokeWidth ?? 0
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(surface.path, paint);
      if (surface.strokeWidth == null) {
        // Close subpixel seams where independently shaded mesh faces meet.
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = .35;
        canvas.drawPath(surface.path, paint);
      }
      if (needsTransform) canvas.restore();
    }
    canvas.restore();
  }
}
