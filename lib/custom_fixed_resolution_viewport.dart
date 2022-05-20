import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';

class CustomFixedResolutionViewport extends Viewport {
  /// By default, this viewport will clip anything rendered outside.
  /// Use this variable to control that behaviour.
  bool noClip;

  @override
  late Vector2 effectiveSize;

  final Vector2 _scaledSize = Vector2.zero();
  Vector2 get scaledSize => _scaledSize.clone();

  final Vector2 _resizeOffset = Vector2.zero();
  Vector2 get resizeOffset => _resizeOffset.clone();

  late double _scale;
  double get scale => _scale;

  /// The matrix used for scaling and translating the canvas
  final Matrix4 _transform = Matrix4.identity();

  /// The Rect that is used to clip the canvas
  late Rect _clipRect;

  CustomFixedResolutionViewport(this.effectiveSize, {this.noClip = false});

  @override
  void resize(Vector2 newCanvasSize) {
    canvasSize = newCanvasSize.clone();

    _scale = math.min(
      canvasSize!.x / effectiveSize.x,
      canvasSize!.y / effectiveSize.y,
    ).ceilToDouble();

    _scaledSize
      ..setFrom(effectiveSize)
      ..scale(_scale);
    _resizeOffset
      ..setFrom(canvasSize!)
      ..sub(_scaledSize)
      ..scale(0.5)..round();

    _clipRect = _resizeOffset & _scaledSize;

    _transform.setIdentity();
    _transform.translate(_resizeOffset.x, _resizeOffset.y);
    _transform.scale(_scale, _scale, 1);
  }

  @override
  void apply(Canvas c) {
    if (!noClip) {
      c.clipRect(_clipRect);
    }
    c.transform(_transform.storage);
  }

  @override
  Vector2 projectVector(Vector2 viewportCoordinates) {
    return (viewportCoordinates * _scale)..add(_resizeOffset);
  }

  @override
  Vector2 unprojectVector(Vector2 screenCoordinates) {
    return (screenCoordinates - _resizeOffset)..scale(1 / _scale);
  }

  @override
  Vector2 scaleVector(Vector2 viewportCoordinates) {
    return viewportCoordinates * scale;
  }

  @override
  Vector2 unscaleVector(Vector2 screenCoordinates) {
    return screenCoordinates / scale;
  }
}