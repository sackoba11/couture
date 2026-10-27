import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/measurement.dart';
import '../models/pattern.dart';

/// Dessin d'un patron généré à partir des mesures d'une fiche.
class PatternSketch extends StatelessWidget {
  const PatternSketch({
    super.key,
    required this.pattern,
    this.measurements = const {},
    this.height = 330,
  });

  final SewingPattern pattern;
  final Map<String, double> measurements;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E6DF)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF8), Color(0xFFFBF1EB)],
        ),
      ),
      child: CustomPaint(
        painter: PatternSketchPainter(
          pattern: pattern,
          measurements: measurements,
          ink: theme.colorScheme.primary,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Peint la silhouette du patron et annote les mesures disponibles.
class PatternSketchPainter extends CustomPainter {
  PatternSketchPainter({
    required this.pattern,
    required this.measurements,
    required this.ink,
  });

  final SewingPattern pattern;
  final Map<String, double> measurements;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final m = _SketchMetrics(pattern: pattern, measurements: measurements, size: size);
    _paintBackground(canvas, m);

    switch (pattern.silhouette) {
      case PatternSilhouette.grandBoubou:
        _paintGrandBoubou(canvas, m);
      case PatternSilhouette.tailleBasse:
        _paintTailleBasse(canvas, m);
      case PatternSilhouette.kaftan:
        _paintKaftan(canvas, m);
      case PatternSilhouette.ensemble:
        _paintEnsemble(canvas, m);
      case PatternSilhouette.robe:
        _paintRobe(canvas, m);
      case PatternSilhouette.jupe:
        _paintJupe(canvas, m);
      case PatternSilhouette.chemise:
        _paintChemise(canvas, m);
      case PatternSilhouette.pantalon:
        _paintPantalon(canvas, m);
      case PatternSilhouette.costume:
        _paintCostume(canvas, m);
    }

    _paintAnnotations(canvas, m);
  }

  // ------------------------------------------------------------- Peintures

  Paint get _fill => Paint()
    ..style = PaintingStyle.fill
    ..color = ink.withValues(alpha: 0.075);

  Paint get _line => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.7
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = ink.withValues(alpha: 0.82);

  Paint _seam(double u) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0 * u
    ..color = ink.withValues(alpha: 0.42);

  Paint _light(double u) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9 * u
    ..color = ink.withValues(alpha: 0.20);

  // --------------------------------------------------------------- Fond

  void _paintBackground(Canvas canvas, _SketchMetrics m) {
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = ink.withValues(alpha: 0.045);
    for (double y = m.top; y < m.size.height; y += 26 * m.u) {
      canvas.drawLine(
        Offset(14, y),
        Offset(m.size.width - 14, y),
        grid,
      );
    }

    _dashedLine(
      canvas,
      Offset(m.cx, m.top - 6),
      Offset(m.cx, m.size.height - 10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = ink.withValues(alpha: 0.12),
      dash: 4,
      gap: 5,
    );
  }

  // -------------------------------------------------------- Grand boubou

  void _paintGrandBoubou(Canvas canvas, _SketchMetrics m) {
    final u = m.u;
    final hemHalf = m.hemHalf(1.52);

    _drawSleevePair(
      canvas,
      m,
      m.leftSleeve(
        wristOuterX: m.cx - m.chestHalf - 36 * u,
        wristY: m.waistY + 14 * u,
        wristWidth: 22 * u,
      ),
      wristY: m.waistY + 14 * u,
      wristOuterX: m.cx - m.chestHalf - 36 * u,
      wristWidth: 22 * u,
    );

    final half = _halfBody(
      m,
      neckHalf: m.neckHalf,
      neckDepth: m.neckDepth,
      shoulderHalf: m.shoulderHalf,
      chestHalf: m.chestHalf,
      waistHalf: m.waistHalf,
      hipHalf: m.hipHalf,
      hemHalf: hemHalf,
      hemY: m.hemY,
      drape: 10 * u,
    );
    _drawBody(canvas, m, half);

    // Broderie du col et panneau central.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(m.cx, m.shoulderY - 1),
        width: m.neckHalf * 2.7,
        height: m.neckDepth * 2.8,
      ),
      0.15,
      math.pi - 0.3,
      false,
      _seam(u),
    );
    _dashedLine(
      canvas,
      Offset(m.cx, m.chestY + 6 * u),
      Offset(m.cx, m.hemY - 18 * u),
      _seam(u),
      dash: 5,
      gap: 4,
    );
    _dashedLine(
      canvas,
      Offset(m.cx - m.chestHalf + 2, m.chestY + 16 * u),
      Offset(m.cx - hemHalf + 6 * u, m.hemY - 16 * u),
      _seam(u),
      dash: 4,
      gap: 6,
    );
    _dashedLine(
      canvas,
      Offset(m.cx + m.chestHalf - 2, m.chestY + 16 * u),
      Offset(m.cx + hemHalf - 6 * u, m.hemY - 16 * u),
      _seam(u),
      dash: 4,
      gap: 6,
    );

    // Ourlet.
    _dashedLine(
      canvas,
      Offset(m.cx - hemHalf * 0.86, m.hemY - 12 * u),
      Offset(m.cx + hemHalf * 0.86, m.hemY - 12 * u),
      _light(u),
      dash: 3,
      gap: 4,
    );
  }

  // -------------------------------------------------------- Taille basse

  void _paintTailleBasse(Canvas canvas, _SketchMetrics m) {
    final u = m.u;
    final hemHalf = m.hemHalf(1.38);

    // Jupe portée sur les hanches (dessinée d'abord).
    final skirt = _skirtHalf(
      m,
      topY: m.hipY - 4 * u,
      topHalf: m.hipHalf,
      hipHalf: m.hipHalf,
      hemHalf: hemHalf,
      hemY: m.hemY,
      drape: 6 * u,
    );
    _drawBody(canvas, m, skirt);

    // Ceinture basse.
    canvas.drawRect(
      Rect.fromLTRB(
        m.cx - m.hipHalf,
        m.hipY - 9 * u,
        m.cx + m.hipHalf,
        m.hipY + 1 * u,
      ),
      _fill,
    );
    canvas.drawLine(
      Offset(m.cx - m.hipHalf, m.hipY - 9 * u),
      Offset(m.cx + m.hipHalf, m.hipY - 9 * u),
      _line,
    );
    canvas.drawLine(
      Offset(m.cx - m.hipHalf, m.hipY + 1 * u),
      Offset(m.cx + m.hipHalf, m.hipY + 1 * u),
      _seam(u),
    );
    for (double dx = -m.hipHalf + 10 * u; dx < m.hipHalf; dx += 16 * u) {
      _dashedLine(
        canvas,
        Offset(m.cx + dx, m.hipY - 7 * u),
        Offset(m.cx + dx, m.hipY - 2 * u),
        _light(u),
        dash: 2,
        gap: 3,
      );
    }

    // Haut ajusté qui s'arrête sur la ceinture.
    _drawSleevePair(
      canvas,
      m,
      m.leftSleeve(
        wristOuterX: m.cx - m.chestHalf - 18 * u,
        wristY: m.waistY + 22 * u,
        wristWidth: 14 * u,
      ),
      wristY: m.waistY + 22 * u,
      wristOuterX: m.cx - m.chestHalf - 18 * u,
      wristWidth: 14 * u,
    );
    final top = _halfBody(
      m,
      neckHalf: m.neckHalf,
      neckDepth: m.neckDepth,
      shoulderHalf: m.shoulderHalf,
      chestHalf: m.chestHalf,
      waistHalf: m.waistHalf,
      hipHalf: m.waistHalf + 3 * u,
      hemHalf: m.waistHalf + 4 * u,
      hemY: m.hipY + 2 * u,
      drape: 4 * u,
      stopAtHip: true,
    );
    _drawBody(canvas, m, top);
    _dashedLine(
      canvas,
      Offset(m.cx - m.waistHalf, m.hipY - 6 * u),
      Offset(m.cx + m.waistHalf, m.hipY - 6 * u),
      _seam(u),
      dash: 5,
      gap: 4,
    );
  }

  // -------------------------------------------------------------- Kaftan

  void _paintKaftan(Canvas canvas, _SketchMetrics m) {
    final u = m.u;
    final hemHalf = m.hemHalf(1.2);

    _drawSleevePair(
      canvas,
      m,
      m.leftSleeve(
        wristOuterX: m.cx - m.chestHalf - 18 * u,
        wristY: m.kneeY - 16 * u,
        wristWidth: 13 * u,
        shoulderInset: 1,
      ),
      wristY: m.kneeY - 16 * u,
      wristOuterX: m.cx - m.chestHalf - 18 * u,
      wristWidth: 13 * u,
    );

    final half = _halfBody(
      m,
      neckHalf: m.neckHalf,
      neckDepth: m.neckDepth,
      shoulderHalf: m.shoulderHalf,
      chestHalf: m.chestHalf,
      waistHalf: m.waistHalf + 2 * u,
      hipHalf: m.hipHalf,
      hemHalf: hemHalf,
      hemY: m.hemY,
      drape: 3 * u,
    );
    _drawBody(canvas, m, half);

    // Fente et boutons.
    _dashedLine(
      canvas,
      Offset(m.cx, m.shoulderY + m.neckDepth),
      Offset(m.cx, m.hemY - 14 * u),
      _seam(u),
      dash: 5,
      gap: 4,
    );
    for (var i = 0; i < 5; i++) {
      final y = m.chestY + i * (m.hemY - m.chestY) / 6;
      canvas.drawCircle(Offset(m.cx, y), 1.8 * u, _seam(u));
    }
    _dashedLine(
      canvas,
      Offset(m.cx - hemHalf + 2, m.hemY - 24 * u),
      Offset(m.cx - hemHalf + 2, m.hemY - 2 * u),
      _light(u),
      dash: 3,
      gap: 3,
    );
    _dashedLine(
      canvas,
      Offset(m.cx + hemHalf - 2, m.hemY - 24 * u),
      Offset(m.cx + hemHalf - 2, m.hemY - 2 * u),
      _light(u),
      dash: 3,
      gap: 3,
    );
  }

  // ------------------------------------------------------------ Ensemble

  void _paintEnsemble(Canvas canvas, _SketchMetrics m) {
    final u = m.u;
    final hemHalf = m.hemHalf(1.32);

    // Jupe taille naturelle.
    final skirt = _skirtHalf(
      m,
      topY: m.waistY,
      topHalf: m.waistHalf,
      hipHalf: m.hipHalf,
      hemHalf: hemHalf,
      hemY: m.hemY,
      drape: 5 * u,
    );
    _drawBody(canvas, m, skirt);

    // Ceinture de jupe.
    canvas.drawRect(
      Rect.fromLTRB(
        m.cx - m.waistHalf,
        m.waistY - 8 * u,
        m.cx + m.waistHalf,
        m.waistY + 1 * u,
      ),
      _fill,
    );
    canvas.drawLine(
      Offset(m.cx - m.waistHalf, m.waistY - 8 * u),
      Offset(m.cx + m.waistHalf, m.waistY - 8 * u),
      _line,
    );
    canvas.drawLine(
      Offset(m.cx - m.waistHalf, m.waistY + 1 * u),
      Offset(m.cx + m.waistHalf, m.waistY + 1 * u),
      _seam(u),
    );

    // Haut avec basque.
    _drawSleevePair(
      canvas,
      m,
      m.leftSleeve(
        wristOuterX: m.cx - m.chestHalf - 16 * u,
        wristY: m.waistY + 4 * u,
        wristWidth: 12 * u,
      ),
      wristY: m.waistY + 4 * u,
      wristOuterX: m.cx - m.chestHalf - 16 * u,
      wristWidth: 12 * u,
    );
    final top = _halfBody(
      m,
      neckHalf: m.neckHalf,
      neckDepth: m.neckDepth,
      shoulderHalf: m.shoulderHalf,
      chestHalf: m.chestHalf,
      waistHalf: m.waistHalf,
      hipHalf: m.waistHalf + 2 * u,
      hemHalf: m.waistHalf + 9 * u,
      hemY: m.waistY + 4 * u,
      drape: 4 * u,
      stopAtHip: true,
    );
    _drawBody(canvas, m, top);
    _dashedLine(
      canvas,
      Offset(m.cx - m.waistHalf + 2, m.waistY - 4 * u),
      Offset(m.cx + m.waistHalf - 2, m.waistY - 4 * u),
      _seam(u),
      dash: 5,
      gap: 4,
    );
  }

  // -------------------------------------------------------- Robe sirène

  void _paintRobe(Canvas canvas, _SketchMetrics m) {
    final u = m.u;
    final hemHalf = m.hemHalf(1.5);
    final kneeHalf = m.hipHalf * 0.94;

    // Manches courtes.
    _drawSleevePair(
      canvas,
      m,
      m.leftSleeve(
        wristOuterX: m.cx - m.chestHalf - 6 * u,
        wristY: m.chestY + 6 * u,
        wristWidth: 7 * u,
      ),
      wristY: m.chestY + 6 * u,
      wristOuterX: m.cx - m.chestHalf - 6 * u,
      wristWidth: 7 * u,
    );

    final half = Path()
      ..moveTo(m.cx, m.shoulderY + m.neckDepth)
      ..quadraticBezierTo(
        m.cx - m.neckHalf * 0.5,
        m.shoulderY + m.neckDepth,
        m.cx - m.neckHalf,
        m.shoulderY,
      )
      ..lineTo(m.cx - m.shoulderHalf, m.shoulderY + 2 * u)
      ..cubicTo(
        m.cx - m.chestHalf, m.chestY - 14 * u,
        m.cx - m.chestHalf, m.chestY,
        m.cx - m.chestHalf, m.chestY,
      )
      ..cubicTo(
        m.cx - m.chestHalf, m.waistY - 22 * u,
        m.cx - m.waistHalf - 2 * u, m.waistY - 8 * u,
        m.cx - m.waistHalf, m.waistY,
      )
      ..cubicTo(
        m.cx - m.waistHalf - 2 * u, m.hipY - 16 * u,
        m.cx - m.hipHalf, m.hipY - 10 * u,
        m.cx - m.hipHalf, m.hipY,
      )
      ..cubicTo(
        m.cx - m.hipHalf + 1 * u, m.kneeY - 20 * u,
        m.cx - kneeHalf, m.kneeY,
        m.cx - kneeHalf, m.kneeY,
      )
      ..cubicTo(
        m.cx - kneeHalf - 4 * u, m.kneeY + (m.hemY - m.kneeY) * 0.35,
        m.cx - hemHalf, m.hemY - 20 * u,
        m.cx - hemHalf, m.hemY,
      )
      ..quadraticBezierTo(
        m.cx - hemHalf * 0.45,
        m.hemY + 5 * u,
        m.cx,
        m.hemY,
      )
      ..close();
    _drawBody(canvas, m, half);

    // Pinces et coutures princesse.
    _dashedLine(
      canvas,
      Offset(m.cx - m.ecartHalf, m.chestY - 2 * u),
      Offset(m.cx - m.ecartHalf * 0.9, m.waistY - 2 * u),
      _seam(u),
      dash: 5,
      gap: 4,
    );
    _dashedLine(
      canvas,
      Offset(m.cx + m.ecartHalf, m.chestY - 2 * u),
      Offset(m.cx + m.ecartHalf * 0.9, m.waistY - 2 * u),
      _seam(u),
      dash: 5,
      gap: 4,
    );
    _dashedLine(
      canvas,
      Offset(m.cx - m.waistHalf * 0.55, m.hipY + 4 * u),
      Offset(m.cx - kneeHalf * 0.8, m.kneeY - 4 * u),
      _seam(u),
      dash: 4,
      gap: 5,
    );
    _dashedLine(
      canvas,
      Offset(m.cx + m.waistHalf * 0.55, m.hipY + 4 * u),
      Offset(m.cx + kneeHalf * 0.8, m.kneeY - 4 * u),
      _seam(u),
      dash: 4,
      gap: 5,
    );
  }

  // ---------------------------------------------------------------- Jupe

  void _paintJupe(Canvas canvas, _SketchMetrics m) {
    final u = m.u;
    final hemHalf = m.hemHalf(1.35);

    final skirt = _skirtHalf(
      m,
      topY: m.waistY,
      topHalf: m.waistHalf,
      hipHalf: m.hipHalf,
      hemHalf: hemHalf,
      hemY: m.hemY,
      drape: 6 * u,
    );
    _drawBody(canvas, m, skirt);

    // Ceinture.
    final band = Rect.fromLTRB(
      m.cx - m.waistHalf,
      m.waistY - 12 * u,
      m.cx + m.waistHalf,
      m.waistY,
    );
    canvas.drawRect(band, _fill);
    canvas.drawRect(band, _line);
    canvas.drawCircle(Offset(m.cx, m.waistY - 6 * u), 2.2 * u, _seam(u));

    // Pinces.
    for (final dx in [-0.5, -0.18, 0.18, 0.5]) {
      _dashedLine(
        canvas,
        Offset(m.cx + m.waistHalf * dx, m.waistY + 1 * u),
        Offset(m.cx + m.waistHalf * dx, m.waistY + 28 * u),
        _seam(u),
        dash: 3,
        gap: 3,
      );
    }
    _dashedLine(
      canvas,
      Offset(m.cx - hemHalf * 0.9, m.hemY - 12 * u),
      Offset(m.cx + hemHalf * 0.9, m.hemY - 12 * u),
      _light(u),
      dash: 3,
      gap: 4,
    );
  }

  // ------------------------------------------------------------- Chemise

  void _paintChemise(Canvas canvas, _SketchMetrics m) {
    final u = m.u;
    final hemHalf = m.hemHalf(1.06);

    _drawSleevePair(
      canvas,
      m,
      m.leftSleeve(
        wristOuterX: m.cx - m.chestHalf - 10 * u,
        wristY: m.kneeY - 30 * u,
        wristWidth: 11 * u,
      ),
      wristY: m.kneeY - 30 * u,
      wristOuterX: m.cx - m.chestHalf - 10 * u,
      wristWidth: 11 * u,
    );

    final half = _halfBody(
      m,
      neckHalf: m.neckHalf,
      neckDepth: m.neckDepth,
      shoulderHalf: m.shoulderHalf,
      chestHalf: m.chestHalf,
      waistHalf: m.waistHalf + 2 * u,
      hipHalf: m.hipHalf,
      hemHalf: hemHalf,
      hemY: m.hemY,
      drape: 2 * u,
    );
    _drawBody(canvas, m, half);

    // Col.
    final collarLeft = Path()
      ..moveTo(m.cx - m.neckHalf, m.shoulderY)
      ..lineTo(m.cx - m.neckHalf - 5 * u, m.shoulderY - 6 * u)
      ..lineTo(m.cx - m.neckHalf + 4 * u, m.shoulderY + 4 * u)
      ..close();
    canvas.drawPath(collarLeft, _fill);
    canvas.drawPath(collarLeft, _line);
    canvas.save();
    canvas.translate(m.cx * 2, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(collarLeft, _fill);
    canvas.drawPath(collarLeft, _line);
    canvas.restore();

    // Patte boutonnée.
    final placketX = m.cx + 7 * u;
    canvas.drawLine(
      Offset(placketX, m.shoulderY + m.neckDepth + 2),
      Offset(placketX, m.hemY - 4 * u),
      _seam(u),
    );
    for (var i = 0; i < 6; i++) {
      final y = m.chestY + i * (m.hemY - m.chestY) / 7;
      canvas.drawCircle(Offset(placketX, y), 1.7 * u, _seam(u));
    }

    // Poche poitrine.
    final pocket = Rect.fromLTWH(
      m.cx - m.chestHalf * 0.72,
      m.chestY + 16 * u,
      24 * u,
      20 * u,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pocket, Radius.circular(2 * u)),
      _light(u),
    );

    // Empiècement dos.
    _dashedLine(
      canvas,
      Offset(m.cx - m.chestHalf, m.chestY - 8 * u),
      Offset(m.cx + m.chestHalf, m.chestY - 8 * u),
      _light(u),
      dash: 4,
      gap: 4,
    );
  }

  // ------------------------------------------------------------ Pantalon

  void _paintPantalon(Canvas canvas, _SketchMetrics m) {
    final u = m.u;
    final path = _pantsPath(m);
    canvas.drawPath(path, _fill);
    canvas.drawPath(path, _line);

    // Ceinture.
    canvas.drawLine(
      Offset(m.cx - m.hipHalf, m.waistY + 13 * u),
      Offset(m.cx + m.hipHalf, m.waistY + 13 * u),
      _seam(u),
    );
    // Braguette.
    canvas.drawLine(
      Offset(m.cx, m.waistY + 13 * u),
      Offset(m.cx, m.crotchY - 4 * u),
      _seam(u),
    );
    // Pinces et poches.
    for (final dx in [-0.62, -0.32, 0.32, 0.62]) {
      _dashedLine(
        canvas,
        Offset(m.cx + m.hipHalf * dx, m.waistY + 2 * u),
        Offset(m.cx + m.hipHalf * dx, m.waistY + 18 * u),
        _light(u),
        dash: 3,
        gap: 3,
      );
    }
    for (final side in [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(m.cx + side * m.hipHalf * 0.72, m.hipY + 2 * u),
          width: 26 * u,
          height: 32 * u,
        ),
        side < 0 ? -math.pi / 2 : math.pi / 2,
        math.pi / 2,
        false,
        _seam(u),
      );
    }
    // Revers de cheville.
    for (final side in [-1.0, 1.0]) {
      _dashedLine(
        canvas,
        Offset(m.cx + side * m.legOuterAtHem(m) * 0.55, m.hemY - 12 * u),
        Offset(m.cx + side * m.legOuterAtHem(m) * 0.95, m.hemY - 12 * u),
        _light(u),
        dash: 3,
        gap: 3,
      );
    }
  }

  // ------------------------------------------------------------- Costume

  void _paintCostume(Canvas canvas, _SketchMetrics m) {
    final u = m.u;

    // Pantalon dessiné d'abord.
    final pants = _pantsPath(m);
    canvas.drawPath(pants, _fill);
    canvas.drawPath(pants, _line);
    canvas.drawLine(
      Offset(m.cx - m.hipHalf, m.waistY + 13 * u),
      Offset(m.cx + m.hipHalf, m.waistY + 13 * u),
      _seam(u),
    );

    // Veste.
    final jacketHem = m.hipY + 16 * u;
    _drawSleevePair(
      canvas,
      m,
      m.leftSleeve(
        wristOuterX: m.cx - m.chestHalf - 16 * u,
        wristY: jacketHem + 6 * u,
        wristWidth: 13 * u,
      ),
      wristY: jacketHem + 6 * u,
      wristOuterX: m.cx - m.chestHalf - 16 * u,
      wristWidth: 13 * u,
    );

    final half = _halfBody(
      m,
      neckHalf: m.neckHalf,
      neckDepth: m.neckDepth,
      shoulderHalf: m.shoulderHalf,
      chestHalf: m.chestHalf,
      waistHalf: m.waistHalf,
      hipHalf: m.hipHalf,
      hemHalf: m.hipHalf + 2 * u,
      hemY: jacketHem,
      drape: 2 * u,
      stopAtHip: true,
    );
    _drawBody(canvas, m, half);

    // Revers et boutons.
    final neckY = m.shoulderY + m.neckDepth;
    canvas.drawLine(
      Offset(m.cx - m.neckHalf, neckY - 4 * u),
      Offset(m.cx, m.waistY - 8 * u),
      _seam(u),
    );
    canvas.drawLine(
      Offset(m.cx + m.neckHalf, neckY - 4 * u),
      Offset(m.cx, m.waistY - 8 * u),
      _seam(u),
    );
    canvas.drawLine(
      Offset(m.cx, m.waistY - 8 * u),
      Offset(m.cx, jacketHem - 4 * u),
      _seam(u),
    );
    for (var i = 0; i < 2; i++) {
      canvas.drawCircle(
        Offset(m.cx, m.waistY + i * 14 * u),
        1.9 * u,
        _seam(u),
      );
    }
    // Poches de veste.
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(m.cx + side * m.hipHalf * 0.55, m.hipY - 6 * u),
        Offset(m.cx + side * m.hipHalf * 0.95, m.hipY - 6 * u),
        _seam(u),
      );
    }
    // Ourlet de veste.
    _dashedLine(
      canvas,
      Offset(m.cx - m.hipHalf, jacketHem - 2 * u),
      Offset(m.cx + m.hipHalf, jacketHem - 2 * u),
      _light(u),
      dash: 4,
      gap: 3,
    );
  }

  // ------------------------------------------------------------ Formes

  /// Demi-corps (gauche) du haut jusqu'au centre de l'ourlet.
  Path _halfBody(
    _SketchMetrics m, {
    required double neckHalf,
    required double neckDepth,
    required double shoulderHalf,
    required double chestHalf,
    required double waistHalf,
    required double hipHalf,
    required double hemHalf,
    required double hemY,
    required double drape,
    bool stopAtHip = false,
  }) {
    final u = m.u;
    final top = m.shoulderY;
    final path = Path()
      ..moveTo(m.cx, top + neckDepth)
      ..quadraticBezierTo(
        m.cx - neckHalf * 0.5,
        top + neckDepth,
        m.cx - neckHalf,
        top,
      )
      ..lineTo(m.cx - shoulderHalf, top + 2 * u)
      ..cubicTo(
        m.cx - shoulderHalf - 2 * u,
        m.chestY - 16 * u,
        m.cx - chestHalf,
        m.chestY - 18 * u,
        m.cx - chestHalf,
        m.chestY,
      )
      ..cubicTo(
        m.cx - chestHalf,
        m.waistY - 24 * u,
        m.cx - waistHalf - 3 * u,
        m.waistY - 10 * u,
        m.cx - waistHalf,
        m.waistY,
      );
    if (stopAtHip) {
      path
        ..cubicTo(
          m.cx - waistHalf - 2 * u,
          m.hipY - 10 * u,
          m.cx - hipHalf,
          m.hipY - 8 * u,
          m.cx - hipHalf,
          m.hipY,
        )
        ..lineTo(m.cx - hemHalf, hemY)
        ..quadraticBezierTo(m.cx, hemY + drape, m.cx, hemY)
        ..close();
      return path;
    }
    path
      ..cubicTo(
        m.cx - waistHalf - 4 * u,
        m.hipY - 6 * u,
        m.cx - hipHalf,
        m.hipY - 12 * u,
        m.cx - hipHalf,
        m.hipY,
      )
      ..cubicTo(
        m.cx - hipHalf - (hemHalf - hipHalf) * 0.05,
        m.hipY + (hemY - m.hipY) * 0.4,
        m.cx - hemHalf + 4 * u,
        hemY - (hemY - m.hipY) * 0.32,
        m.cx - hemHalf,
        hemY,
      )
      ..quadraticBezierTo(m.cx, hemY + drape, m.cx, hemY)
      ..close();
    return path;
  }

  /// Demi-jupe (gauche) depuis la taille ou les hanches jusqu'à l'ourlet.
  Path _skirtHalf(
    _SketchMetrics m, {
    required double topY,
    required double topHalf,
    required double hipHalf,
    required double hemHalf,
    required double hemY,
    required double drape,
  }) {
    final u = m.u;
    final hipStart = math.max(topY + 6 * u, m.hipY);
    return Path()
      ..moveTo(m.cx, topY)
      ..lineTo(m.cx - topHalf, topY)
      ..cubicTo(
        m.cx - topHalf,
        topY + (hipStart - topY) * 0.55,
        m.cx - hipHalf,
        hipStart - 12 * u,
        m.cx - hipHalf,
        hipStart,
      )
      ..cubicTo(
        m.cx - hipHalf - (hemHalf - hipHalf) * 0.08,
        hipStart + (hemY - hipStart) * 0.42,
        m.cx - hemHalf + 4 * u,
        hemY - (hemY - hipStart) * 0.3,
        m.cx - hemHalf,
        hemY,
      )
      ..quadraticBezierTo(m.cx, hemY + drape, m.cx, hemY)
      ..close();
  }

  Path _pantsPath(_SketchMetrics m) {
    final u = m.u;
    final crotch = m.crotchY;
    final legOuter = m.legOuterAtHem(m);
    final legInner = m.legInnerAtHem(m);
    final gap = m.legGapAtHem(m);

    return Path()
      ..moveTo(m.cx - m.hipHalf, m.waistY)
      ..lineTo(m.cx + m.hipHalf, m.waistY)
      ..lineTo(m.cx + m.hipHalf, m.hipY)
      ..quadraticBezierTo(
        m.cx + legOuter * 0.9,
        crotch,
        m.cx + legOuter,
        m.hemY - 2 * u,
      )
      ..quadraticBezierTo(
        m.cx + legOuter * 0.55,
        m.hemY + 2 * u,
        m.cx + legInner,
        m.hemY,
      )
      ..lineTo(m.cx + gap, crotch)
      ..lineTo(m.cx - gap, crotch)
      ..lineTo(m.cx - legInner, m.hemY)
      ..quadraticBezierTo(
        m.cx - legOuter * 0.55,
        m.hemY + 2 * u,
        m.cx - legOuter,
        m.hemY - 2 * u,
      )
      ..quadraticBezierTo(
        m.cx - legOuter * 0.9,
        crotch,
        m.cx - m.hipHalf,
        m.hipY,
      )
      ..close();
  }

  // ----------------------------------------------------------- Sleeves

  void _drawSleevePair(
    Canvas canvas,
    _SketchMetrics m,
    Path left, {
    required double wristY,
    required double wristOuterX,
    required double wristWidth,
  }) {
    final u = m.u;
    canvas.drawPath(left, _fill);
    canvas.drawPath(left, _line);
    canvas.save();
    canvas.translate(m.cx * 2, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(left, _fill);
    canvas.drawPath(left, _line);
    canvas.restore();

    // Ourlet de manche.
    _dashedLine(
      canvas,
      Offset(wristOuterX + 2 * u, wristY - 2 * u),
      Offset(wristOuterX + wristWidth - 1 * u, wristY + 2 * u),
      _light(u),
      dash: 3,
      gap: 3,
    );
    canvas.save();
    canvas.translate(m.cx * 2, 0);
    canvas.scale(-1, 1);
    _dashedLine(
      canvas,
      Offset(wristOuterX + 2 * u, wristY - 2 * u),
      Offset(wristOuterX + wristWidth - 1 * u, wristY + 2 * u),
      _light(u),
      dash: 3,
      gap: 3,
    );
    canvas.restore();
  }

  void _drawBody(Canvas canvas, _SketchMetrics m, Path leftHalf) {
    final right = leftHalf.transform(
      Float64List.fromList(<double>[
        -1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        2 * m.cx, 0, 0, 1,
      ]),
    );
    final body = Path.combine(PathOperation.union, leftHalf, right);
    canvas.drawPath(body, _fill);
    canvas.drawPath(body, _line);
  }

  // -------------------------------------------------------- Annotations

  void _paintAnnotations(Canvas canvas, _SketchMetrics m) {
    final u = m.u;
    final annotations = <_Annotation>[];

    if (measurements.containsKey('largeur_epaules')) {
      annotations.add(
        _Annotation(
          anchor: Offset(m.cx - m.shoulderHalf, m.shoulderY),
          text: 'Épaules ${formatMeasure(measurements['largeur_epaules']!)}',
          right: false,
        ),
      );
    }
    if (measurements.containsKey('tour_poitrine')) {
      annotations.add(
        _Annotation(
          anchor: Offset(m.cx + m.chestHalf, m.chestY),
          text: 'Poitrine ${formatMeasure(measurements['tour_poitrine']!)}',
          right: true,
        ),
      );
    }
    if (measurements.containsKey('tour_taille')) {
      annotations.add(
        _Annotation(
          anchor: Offset(m.cx - m.waistHalf, m.waistY + 2 * u),
          text: 'Taille ${formatMeasure(measurements['tour_taille']!)}',
          right: false,
        ),
      );
    }
    if (measurements.containsKey('tour_hanches')) {
      annotations.add(
        _Annotation(
          anchor: Offset(m.cx + m.hipHalf, m.hipY + 2 * u),
          text: 'Hanches ${formatMeasure(measurements['tour_hanches']!)}',
          right: true,
        ),
      );
    }

    for (final annotation in annotations) {
      _drawAnnotation(
        canvas,
        m,
        anchor: annotation.anchor,
        text: annotation.text,
        right: annotation.right,
      );
    }

    _drawLengthAnnotation(canvas, m);
  }

  void _drawLengthAnnotation(Canvas canvas, _SketchMetrics m) {
    final id = m.lengthId;
    if (id == null || !measurements.containsKey(id)) return;

    final u = m.u;
    final topY = m.lengthStartY;
    final hemY = m.hemY;
    final maxX = math.max(30.0, m.size.width - 58 * u);
    final x = (m.cx + m.hemHalf(1.05) + 26 * u).clamp(30.0, maxX);

    final paint = _seam(u);
    _dashedLine(canvas, Offset(x, topY), Offset(x, hemY), paint, dash: 4, gap: 4);
    canvas.drawLine(
      Offset(x - 5 * u, topY),
      Offset(x + 5 * u, topY),
      paint,
    );
    canvas.drawLine(
      Offset(x - 5 * u, hemY),
      Offset(x + 5 * u, hemY),
      paint,
    );

    _drawAnnotation(
      canvas,
      m,
      anchor: Offset(x, (topY + hemY) / 2),
      text: 'Longueur ${formatMeasure(measurements[id]!)}',
      right: true,
    );
  }

  void _drawAnnotation(
    Canvas canvas,
    _SketchMetrics m, {
    required Offset anchor,
    required String text,
    required bool right,
  }) {
    final u = m.u;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: (10.5 * u).clamp(9.0, 12.0),
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: ink.withValues(alpha: 0.8),
          letterSpacing: 0.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final padH = 5 * u;
    final padV = 3 * u;
    final width = painter.width + padH * 2;
    final height = painter.height + padV * 2;
    var left = right ? anchor.dx + 8 * u : anchor.dx - 8 * u - width;
    final maxLeft = math.max(4.0, m.size.width - width - 4);
    left = left.clamp(4.0, maxLeft);
    final maxTop = math.max(4.0, m.size.height - height - 4);
    final top = (anchor.dy - height / 2).clamp(4.0, maxTop);

    final connectorStart = right
        ? Offset(anchor.dx + 1.5, anchor.dy)
        : Offset(anchor.dx - 1.5, anchor.dy);
    final connectorEnd = right
        ? Offset(left, anchor.dy)
        : Offset(left + width, anchor.dy);
    _dashedLine(
      canvas,
      connectorStart,
      connectorEnd,
      _light(u),
      dash: 2,
      gap: 3,
    );

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, width, height),
      Radius.circular(6 * u),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9 * u
        ..color = ink.withValues(alpha: 0.14),
    );
    painter.paint(canvas, Offset(left + padH, top + padV));
  }

  void _dashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dash = 5,
    double gap = 4,
  }) {
    final delta = end - start;
    final length = delta.distance;
    if (length == 0) return;
    final direction = delta / length;
    var distance = 0.0;
    while (distance < length) {
      final next = math.min(distance + dash, length);
      canvas.drawLine(
        start + direction * distance,
        start + direction * next,
        paint,
      );
      distance = next + gap;
    }
  }

  @override
  bool shouldRepaint(covariant PatternSketchPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.ink != ink ||
        !_sameMeasurements(oldDelegate.measurements, measurements);
  }

  bool _sameMeasurements(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

class _Annotation {
  const _Annotation({
    required this.anchor,
    required this.text,
    required this.right,
  });

  final Offset anchor;
  final String text;
  final bool right;
}

/// Géométrie du dessin, dérivée des mesures (avec des valeurs par défaut
/// pour que le patron reste lisible sur une fiche incomplète).
class _SketchMetrics {
  _SketchMetrics({
    required this.pattern,
    required this.measurements,
    required this.size,
  });

  final SewingPattern pattern;
  final Map<String, double> measurements;
  final Size size;

  late final double u = (size.width / 340).clamp(0.72, 1.45);
  late final double cx = size.width / 2;
  late final double top = size.height * 0.07;
  late final double h = size.height * 0.89;
  late final double shoulderY = top + h * 0.055;
  late final double chestY = top + h * 0.20;
  late final double waistY = top + h * 0.375;
  late final double hipY = top + h * 0.465;
  late final double kneeY = top + h * 0.70;
  late final double crotchY = hipY + h * 0.085;

  double get chest => measurements['tour_poitrine'] ?? 94;
  double get waist => measurements['tour_taille'] ?? (chest * 0.82);
  double get hips => measurements['tour_hanches'] ?? (chest * 1.06);
  double get shoulders => measurements['largeur_epaules'] ?? (chest * 0.42);
  double get cou => measurements['tour_cou'] ?? 38;

  late final double maxHalf = size.width * 0.205;
  late final double shoulderHalf = _clamp(shoulders * 0.78 * u, 20 * u, 40 * u);
  late final double chestHalf = _clamp(
    chest * 0.40 * u,
    shoulderHalf + 2 * u,
    maxHalf,
  );
  late final double waistHalf = _clamp(
    waist * 0.36 * u,
    17 * u,
    chestHalf - 2 * u,
  );
  late final double hipHalf = _clamp(
    hips * 0.40 * u,
    waistHalf + 4 * u,
    maxHalf,
  );
  late final double neckHalf = _clamp(cou * 0.20 * u, 8 * u, 13 * u);
  late final double neckDepth = 11 * u;
  late final double ecartHalf = _clamp(
    (measurements['ecart_poitrine'] ?? 18) * 0.45 * u,
    6 * u,
    14 * u,
  );

  /// Mesure de longueur utilisée pour annoter le dessin.
  String? get lengthId {
    switch (pattern.silhouette) {
      case PatternSilhouette.jupe:
        return 'longueur_jupe';
      case PatternSilhouette.pantalon:
      case PatternSilhouette.costume:
        return 'longueur_pantalon';
      case PatternSilhouette.chemise:
        return measurements.containsKey('longueur_dos')
            ? 'longueur_dos'
            : 'longueur_devant';
      case PatternSilhouette.ensemble:
      case PatternSilhouette.tailleBasse:
        return 'longueur_jupe';
      case PatternSilhouette.grandBoubou:
      case PatternSilhouette.kaftan:
      case PatternSilhouette.robe:
        return 'longueur_totale';
    }
  }

  double get _defaultLength {
    switch (pattern.silhouette) {
      case PatternSilhouette.jupe:
        return 80;
      case PatternSilhouette.pantalon:
      case PatternSilhouette.costume:
        return 100;
      case PatternSilhouette.chemise:
        return 76;
      case PatternSilhouette.ensemble:
      case PatternSilhouette.tailleBasse:
        return 82;
      case PatternSilhouette.grandBoubou:
      case PatternSilhouette.kaftan:
      case PatternSilhouette.robe:
        return 140;
    }
  }

  late final double lengthCm =
      measurements[lengthId ?? ''] ?? _defaultLength;

  bool get _lengthStartsAtWaist {
    switch (pattern.silhouette) {
      case PatternSilhouette.jupe:
      case PatternSilhouette.pantalon:
      case PatternSilhouette.costume:
      case PatternSilhouette.ensemble:
      case PatternSilhouette.tailleBasse:
        return true;
      default:
        return false;
    }
  }

  double get lengthStartY => _lengthStartsAtWaist ? waistY : shoulderY;

  late final double hemY = _computeHem();

  double _computeHem() {
    final bottom = size.height * 0.955;
    final start = lengthStartY;
    final t = ((lengthCm - 50) / 100).clamp(0.0, 1.0);
    final factor = 0.62 + 0.38 * t;
    return start + (bottom - start) * factor;
  }

  double hemHalf(double flare) => _clamp(
    hipHalf * flare,
    hipHalf * 0.9,
    size.width * 0.225,
  );

  double legOuterAtHem(_SketchMetrics m) {
    final cuisse = m.measurements['tour_cuisse'] ?? 58;
    final cheville = m.measurements['tour_cheville'] ?? 26;
    final base = (cuisse * 0.30 + cheville * 0.16) * m.u;
    return _clamp(base, m.hipHalf * 0.52, m.hipHalf * 0.9);
  }

  double legInnerAtHem(_SketchMetrics m) {
    final cheville = m.measurements['tour_cheville'] ?? 26;
    return _clamp(cheville * 0.22 * m.u, 6 * m.u, m.hipHalf * 0.4);
  }

  double legGapAtHem(_SketchMetrics m) => m.legInnerAtHem(m) * 0.45;

  Path leftSleeve({
    required double wristOuterX,
    required double wristY,
    required double wristWidth,
    double shoulderInset = 2,
    double shoulderDrop = 2,
  }) {
    final sx = cx - shoulderHalf + shoulderInset * u;
    final sy = shoulderY + shoulderDrop * u;
    final ax = cx - chestHalf - 2 * u;
    final ay = chestY + 10 * u;
    return Path()
      ..moveTo(sx, sy)
      ..cubicTo(
        sx - 8 * u,
        sy + (wristY - sy) * 0.45,
        wristOuterX + 10 * u,
        wristY - 22 * u,
        wristOuterX,
        wristY,
      )
      ..lineTo(wristOuterX + wristWidth, wristY + 4 * u)
      ..cubicTo(
        wristOuterX + wristWidth + 10 * u,
        wristY - 26 * u,
        ax - 4 * u,
        ay + 24 * u,
        ax,
        ay,
      )
      ..close();
  }

  static double _clamp(double value, double min, double max) {
    if (min > max) return max;
    return value < min ? min : (value > max ? max : value);
  }
}
