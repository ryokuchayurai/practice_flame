import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:practice_flame/human1.dart';

class Bat extends SpriteComponent with HasGameRef {
  Bat(this.direction, {this.onComplete});

  final Direction direction;
  final void Function(Bat)? onComplete;
  late final Vector2 force;

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load('bat.png');
    sprite = Sprite(image);
    size = Vector2(image.width.toDouble(), image.height.toDouble());
    anchor = Anchor.centerRight;

    double fromDeg = 0;
    double toDeg = 0;
    switch (direction) {
      case Direction.up:
      case Direction.upLeft:
      case Direction.upRight:
        fromDeg = 0;
        toDeg = 180;
        force = Vector2(0, -50);
        position = Vector2(3, 13);
        break;
      case Direction.left:
        fromDeg = 90;
        toDeg = -90;
        force = Vector2(-50, 0);
        position = Vector2(3, 18);
        break;
      case Direction.right:
        fromDeg = 90;
        toDeg = 270;
        force = Vector2(50, 0);
        position = Vector2(15, 18);
        break;
      case Direction.down:
      case Direction.downLeft:
      case Direction.downRight:
        fromDeg = 0;
        toDeg = -180;
        force = Vector2(0, 50);
        position = Vector2(3, 25);
        break;
    }

    angle = degrees2Radians * fromDeg;

    final hitboxPaint = BasicPalette.red.paint()..style = PaintingStyle.stroke;
    add(RectangleHitbox(
      position: Vector2(0, 0),
      size: size,
    )
      ..paint = hitboxPaint
      ..renderShape = true);

    add(
      RotateEffect.to(
        degrees2Radians * toDeg,
        onComplete: () => onComplete?.call(this),
        EffectController(
          duration: 0.2,
          infinite: false,
        ),
      ),
    );
  }
}
