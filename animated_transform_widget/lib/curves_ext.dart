import 'dart:ui';

import 'package:flutter/animation.dart';
import 'dart:math';

///

class BezierCurve extends Curve {
  final List<double> anchors;

  BezierCurve(this.anchors);

  double _evaluate(double fraction) {
    double result = 0;
    for (int i = 0; i < anchors.length; ++i) {
      final coefficient = (i == 0 || i == anchors.length - 1) ? 1 : (anchors.length - 1);
      result +=
          anchors[i] * coefficient * pow(1 - fraction, (anchors.length - i) - 1) * pow(fraction, i);
    }
    return result;
  }

  @override
  double transformInternal(double t) {
    return _evaluate(t);
  }
}

abstract class OffsetCurve {
  const OffsetCurve();

  Offset transform(double t);
}

abstract class SizeCurve {
  const SizeCurve();

  Size transform(double t);
}

class SimpleOffsetCurve extends OffsetCurve {
  final Offset from;
  final Offset to;
  final Curve curve;

  const SimpleOffsetCurve(this.from, this.to, {this.curve = Curves.linear});

  Offset _evaluate(double fraction) {
    double dx = to.dx;
    if (to.dx != from.dx) {
      dx = from.dx + (to.dx - from.dx) * curve.transform(fraction);
    }
    double dy = to.dy;
    if (to.dy != from.dy) {
      dy = from.dy + (to.dy - from.dy) * curve.transform(fraction);
    }

    return Offset(dx, dy);
  }

  @override
  Offset transform(double t) {
    return _evaluate(t);
  }
}

class SimpleSizeCurve extends SizeCurve {
  final Size from;
  final Size to;
  final Curve curve;

  const SimpleSizeCurve(this.from, this.to, {this.curve = Curves.linear});

  Size _evaluate(double fraction) {
    double width = to.width;
    if (to.width != from.width) {
      width = from.width + (to.width - from.width) * curve.transform(fraction);
    }
    double height = to.height;
    if (to.height != from.height) {
      height = from.height + (to.height - from.height) * curve.transform(fraction);
    }

    return Size(width, height);
  }

  @override
  Size transform(double t) {
    return _evaluate(t);
  }
}

class BezierOffsetCurve extends OffsetCurve {
  final List<Offset> anchors;

  BezierOffsetCurve(this.anchors);

  Offset _evaluate(double fraction) {
    double dx = 0;
    double dy = 0;
    for (int i = 0; i < anchors.length; ++i) {
      final coefficient = (i == 0 || i == anchors.length - 1) ? 1 : (anchors.length - 1);
      dx += anchors[i].dx *
          coefficient *
          pow(1 - fraction, (anchors.length - i) - 1) *
          pow(fraction, i);
    }
    for (int i = 0; i < anchors.length; ++i) {
      final coefficient = (i == 0 || i == anchors.length - 1) ? 1 : (anchors.length - 1);
      dy += anchors[i].dy *
          coefficient *
          pow(1 - fraction, (anchors.length - i) - 1) *
          pow(fraction, i);
    }
    return Offset(dx, dy);
  }

  @override
  Offset transform(double t) {
    return _evaluate(t);
  }
}

class CurvesExt {}
