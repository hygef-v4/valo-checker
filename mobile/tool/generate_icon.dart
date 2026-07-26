// Generates the ValoCheck launcher icon source PNGs (original artwork:
// angular shield + checkmark in the app palette).
//
// Run from mobile/:  flutter test tool/generate_icon.dart
// Then regenerate platform icons:  dart run flutter_launcher_icons
//
// Outputs (1024x1024):
//   assets/icon/icon.png             full icon, navy background (iOS + legacy Android)
//   assets/icon/icon_foreground.png  transparent, mark scaled to adaptive safe zone
//   assets/icon/icon_monochrome.png  white silhouette for Android 13+ themed icons

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double _canvas = 1024;
const Color _navy = Color(0xFF0F1923);
const Color _red = Color(0xFFFF4655);
const Color _offWhite = Color(0xFFECE8E1);

/// Chamfered flat-top shield, roughly centered on the canvas.
Path _shieldPath() {
  return Path()
    ..moveTo(333, 244)
    ..lineTo(691, 244)
    ..lineTo(724, 277)
    ..lineTo(724, 590)
    ..lineTo(512, 784)
    ..lineTo(300, 590)
    ..lineTo(300, 277)
    ..close();
}

Path _checkPath() {
  return Path()
    ..moveTo(385, 500)
    ..lineTo(479, 596)
    ..lineTo(646, 400);
}

Paint _checkStroke(Color color) {
  return Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 80
    ..strokeCap = StrokeCap.butt
    ..strokeJoin = StrokeJoin.miter
    ..strokeMiterLimit = 10
    ..isAntiAlias = true;
}

void _drawMark(Canvas canvas, {required bool monochrome}) {
  final shield = _shieldPath();
  final bounds = Rect.fromLTWH(0, 0, _canvas, _canvas);

  if (monochrome) {
    // Silhouette: white shield with the checkmark punched out.
    canvas.saveLayer(bounds, Paint());
    canvas.drawPath(shield, Paint()..color = Colors.white..isAntiAlias = true);
    canvas.drawPath(_checkPath(), _checkStroke(Colors.white)..blendMode = BlendMode.clear);
    canvas.restore();
    return;
  }

  canvas.drawPath(shield, Paint()..color = _red..isAntiAlias = true);

  // Subtle vertical facet: darken the right half of the shield.
  canvas.save();
  canvas.clipPath(shield);
  canvas.drawRect(
    Rect.fromLTRB(_canvas / 2, 0, _canvas, _canvas),
    Paint()..color = Colors.black.withValues(alpha: 0.10),
  );
  canvas.restore();

  canvas.drawPath(_checkPath(), _checkStroke(_offWhite));
}

Future<void> _savePng(String path, void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _canvas, _canvas));
  draw(canvas);
  final image = await recorder.endRecording().toImage(_canvas.toInt(), _canvas.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate launcher icon PNGs', () async {
    await _savePng('assets/icon/icon.png', (c) {
      c.drawRect(Rect.fromLTWH(0, 0, _canvas, _canvas), Paint()..color = _navy);
      _drawMark(c, monochrome: false);
    });

    // Adaptive foreground: flutter_launcher_icons already applies a 16%
    // inset for the masked safe zone, so draw the mark slightly LARGER than
    // the base icon to fill the launcher circle nicely.
    await _savePng('assets/icon/icon_foreground.png', (c) {
      c.translate(_canvas / 2, _canvas / 2);
      c.scale(1.15);
      c.translate(-_canvas / 2, -_canvas / 2);
      _drawMark(c, monochrome: false);
    });

    await _savePng('assets/icon/icon_monochrome.png', (c) {
      c.translate(_canvas / 2, _canvas / 2);
      c.scale(1.15);
      c.translate(-_canvas / 2, -_canvas / 2);
      _drawMark(c, monochrome: true);
    });
  });
}
