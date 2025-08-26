// This file contains the logo generation logic
// For now, we'll use a simple colored square as placeholder
// The actual PNG will be generated during build process

import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  
  const LogoWidget({super.key, this.size = 64});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Stack(
        children: [
          // Wallet icon
          Center(
            child: Container(
              width: size * 0.6,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(size * 0.08),
              ),
              child: CustomPaint(
                painter: _LogoPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Draw split line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    
    // Draw rupee symbol (simplified)
    final rupeePath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.3)
      ..moveTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..moveTo(size.width * 0.2, size.height * 0.7)
      ..lineTo(size.width * 0.35, size.height * 0.7);
    
    canvas.drawPath(rupeePath, paint);
    
    // Draw arrows
    final arrowPaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.fill;
    
    // Right arrow
    final rightArrow = Path()
      ..moveTo(size.width * 0.6, size.height * 0.4)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width * 0.8, size.height * 0.4)
      ..lineTo(size.width * 0.7, size.height * 0.5)
      ..close();
    
    canvas.drawPath(rightArrow, arrowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
