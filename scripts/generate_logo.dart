import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Script to generate logo.png from programmatic drawing
/// Run with: dart run scripts/generate_logo.dart
void main() async {
  // Create a custom painter for the logo
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = const Size(1024, 1024);
  
  // Paint the logo
  _paintLogo(canvas, size);
  
  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(1024, 1024);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  if (byteData != null) {
    final file = File('assets/icons/logo.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    print('Logo PNG generated successfully at ${file.path}');
  }
}

void _paintLogo(Canvas canvas, Size size) {
  final center = Offset(size.width / 2, size.height / 2);
  final radius = size.width / 2;
  
  // Background circle
  final bgPaint = Paint()
    ..color = const Color(0xFF0D9488)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(center, radius, bgPaint);
  
  // Wallet base
  final walletPaint = Paint()
    ..color = Colors.white.withOpacity(0.95)
    ..style = PaintingStyle.fill;
  final walletRect = RRect.fromRectAndRadius(
    Rect.fromCenter(center: center, width: 384, height: 256),
    const Radius.circular(32),
  );
  canvas.drawRRect(walletRect, walletPaint);
  
  // Split line (dashed)
  final linePaint = Paint()
    ..color = const Color(0xFF0D9488)
    ..strokeWidth = 8
    ..style = PaintingStyle.stroke;
  
  final lineStart = Offset(center.dx, center.dy - 128);
  final lineEnd = Offset(center.dx, center.dy + 128);
  _drawDashedLine(canvas, lineStart, lineEnd, linePaint, 16, 8);
  
  // Rupee symbol (simplified)
  final rupeePaint = Paint()
    ..color = const Color(0xFF0D9488)
    ..style = PaintingStyle.fill;
  
  final rupeePath = Path()
    ..moveTo(center.dx - 128, center.dy - 32)
    ..lineTo(center.dx - 64, center.dy - 32)
    ..lineTo(center.dx - 64, center.dy - 16)
    ..lineTo(center.dx - 112, center.dy - 16)
    ..lineTo(center.dx - 112, center.dy)
    ..lineTo(center.dx - 80, center.dy)
    ..lineTo(center.dx - 96, center.dy + 32)
    ..lineTo(center.dx - 120, center.dy + 32)
    ..lineTo(center.dx - 104, center.dy)
    ..lineTo(center.dx - 128, center.dy)
    ..close();
  canvas.drawPath(rupeePath, rupeePaint);
  
  // Split arrows
  final arrowPaint = Paint()
    ..color = const Color(0xFF0D9488)
    ..style = PaintingStyle.fill;
  
  // Right arrow
  final rightArrow = Path()
    ..moveTo(center.dx + 64, center.dy - 16)
    ..lineTo(center.dx + 80, center.dy - 32)
    ..lineTo(center.dx + 96, center.dy - 16)
    ..lineTo(center.dx + 80, center.dy)
    ..close();
  canvas.drawPath(rightArrow, arrowPaint);
  
  // Left arrow
  final leftArrow = Path()
    ..moveTo(center.dx + 96, center.dy + 16)
    ..lineTo(center.dx + 80, center.dy)
    ..lineTo(center.dx + 64, center.dy + 16)
    ..lineTo(center.dx + 80, center.dy + 32)
    ..close();
  canvas.drawPath(leftArrow, arrowPaint);
  
  // Decorative circles
  final accentPaint = Paint()
    ..color = const Color(0xFF99F6E4)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(center.dx - 128, center.dy + 64), 8, accentPaint);
  canvas.drawCircle(Offset(center.dx + 128, center.dy + 64), 8, accentPaint);
  
  // Bottom accent line
  final accentRect = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(center.dx, center.dy + 256),
      width: 200,
      height: 4,
    ),
    const Radius.circular(2),
  );
  canvas.drawRRect(accentRect, accentPaint);
}

void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashLength, double gapLength) {
  final distance = (end - start).distance;
  final dashCount = (distance / (dashLength + gapLength)).floor();
  final direction = (end - start) / distance;
  
  for (int i = 0; i < dashCount; i++) {
    final dashStart = start + direction * (i * (dashLength + gapLength));
    final dashEnd = dashStart + direction * dashLength;
    canvas.drawLine(dashStart, dashEnd, paint);
  }
}
