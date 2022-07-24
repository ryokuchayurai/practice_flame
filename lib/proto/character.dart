import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/palette.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

abstract class Character extends SpriteAnimationComponent with HasGameRef {
  List<SpriteAnimation> create4DirectionAnimation(
      SpriteSheet sheet, double stepTime, int from, int to) {
    return [
      sheet.createAnimation(
          row: 0, stepTime: stepTime, loop: true, from: from, to: to),
      sheet.createAnimation(
          row: 1, stepTime: stepTime, loop: true, from: from, to: to),
      sheet.createAnimation(
          row: 2, stepTime: stepTime, loop: true, from: from, to: to),
      sheet.createAnimation(
          row: 3, stepTime: stepTime, loop: true, from: from, to: to),
    ];
  }

  @override
  Future<void>? onLoad() async {
    super.onLoad();

    final image = await gameRef.images.load('shadow.png');
    add(SpriteComponent.fromImage(image,
        paint: Paint()..color = Colors.black.withOpacity(0.2),
        position: Vector2(2, 28),
        size: image.size,
        priority: -1));
  }

  @override
  void update(double dt) {
    super.update(dt);
    priority = position.y.toInt();
  }

  @override
  void renderTree(Canvas canvas) {
    canvas.save();
    canvas.transform(transformMatrix.storage);

    children
        .where((element) => element.priority < 0)
        .forEach((c) => c.renderTree(canvas));
    render(canvas);
    children
        .where((element) => element.priority >= 0)
        .forEach((c) => c.renderTree(canvas));
    if (debugMode) {
      renderDebugMode(canvas);
    }

    canvas.restore();
  }

  bool hasDamage = false;

  void effectDamage({int repeatCount = 10}) {
    hasDamage = true;
    add(
      ColorEffect(
          Colors.white,
          const Offset(0, 1),
          EffectController(
              duration: 0.1, reverseDuration: 0.1, repeatCount: repeatCount),
          onComplete: () => hasDamage = false),
    );
  }
}

mixin CharacterCollisionCallbacks on Component {
  onCollisionStart(CharacterHitbox own, Set<Vector2> intersectionPoints,
      PositionComponent other);
  onCollisionEnd(CharacterHitbox own, PositionComponent other);
}

class CharacterHitbox extends PositionComponent with CollisionCallbacks {
  CharacterHitbox({
    super.position,
    super.size,
    super.angle,
    super.anchor,
    super.priority,
  });

  @override
  Future<void>? onLoad() {
    super.onLoad();

    final hitboxPaint = BasicPalette.white.paint()
      ..style = PaintingStyle.stroke;

    add(RectangleHitbox(
        position: Vector2.zero(),
        size: size,
        angle: angle,
        anchor: anchor,
        priority: priority)
      ..paint = hitboxPaint
      ..renderShape = false);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (parent is CharacterCollisionCallbacks) {
      (parent as CharacterCollisionCallbacks)
          .onCollisionStart(this, intersectionPoints, other);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    if (parent is CharacterCollisionCallbacks) {
      (parent as CharacterCollisionCallbacks).onCollisionEnd(this, other);
    }
  }
}
