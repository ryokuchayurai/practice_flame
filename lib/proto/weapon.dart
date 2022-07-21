import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:practice_flame/proto/direction.dart';
import 'package:practice_flame/proto/info.dart';

class ProtoWeapon extends SpriteComponent with HasGameRef {
  ProtoWeapon(this.direction, {this.onComplete});

  final EightDirection direction;
  final void Function()? onComplete;
  late final Vector2 force;

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load('bat.png');
    sprite = Sprite(image);
    size = Vector2(image.width.toDouble(), image.height.toDouble());
    size = Vector2.all(gameInfo.playerInfo.atackRange)..multiply(size);
    anchor = Anchor.centerRight;

    double fromDeg = 0;
    double toDeg = 0;
    switch (direction) {
      case EightDirection.up:
      case EightDirection.upLeft:
      case EightDirection.upRight:
        fromDeg = 0;
        toDeg = 180;
        force = Vector2(0, gameInfo.playerInfo.knockBack * -1);
        position = Vector2(3, 13);
        break;
      case EightDirection.left:
        fromDeg = 90;
        toDeg = -90;
        force = Vector2(gameInfo.playerInfo.knockBack * -1, 0);
        position = Vector2(3, 18);
        break;
      case EightDirection.right:
        fromDeg = 90;
        toDeg = 270;
        force = Vector2(gameInfo.playerInfo.knockBack, 0);
        position = Vector2(15, 18);
        break;
      case EightDirection.down:
      case EightDirection.downLeft:
      case EightDirection.downRight:
        fromDeg = 0;
        toDeg = -180;
        force = Vector2(0, gameInfo.playerInfo.knockBack);
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
      ..renderShape = false);

    add(
      RotateEffect.to(
        degrees2Radians * toDeg,
        onComplete: () {
          removeFromParent();
          onComplete?.call();
        },
        EffectController(
          duration: 0.2,
          infinite: false,
        ),
      ),
    );
  }
}
