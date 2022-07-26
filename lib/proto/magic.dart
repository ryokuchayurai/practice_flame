import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:practice_flame/proto/hitbox.dart';
import 'package:practice_flame/proto/proto_game.dart';

class ProtoMagic extends SpriteAnimationComponent with HasGameRef {
  ProtoMagic({super.position, required this.target});

  final Vector2 target;
  final double speed = 200;
  late Vector2 force;
  late Vector2 targetFar;

  @override
  Future<void> onLoad() async {
    size = Vector2(10, 5);

    angle = atan2(target.y - position.y, target.x - position.x);
    double deg = angle * radians2Degrees + (Random().nextDouble() * 60 - 30);
    angle = deg * degrees2Radians;

    force = Vector2(cos(angle) * 70, sin(angle) * 70);
    targetFar = Vector2(cos(angle) * 200, sin(angle) * 200)..add(position);

    debugPrint('magic -> $targetFar');
    (gameRef as ProtoGame).showPoint(targetFar);

    final image = await gameRef.images.load('magic-arrow.png');
    final spriteSheet = SpriteSheet(image: image, srcSize: size);

    animation = spriteSheet.createAnimation(row: 0, stepTime: 0.1);

    add(RectangleHitbox(
      position: Vector2(0, 0),
      size: size,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.moveToTarget(targetFar, speed * dt);
    if (targetFar.distanceTo(position).abs() < 1) {
      removeFromParent();
    }
  }
}

class FireMagic extends SpriteAnimationComponent with HasGameRef {
  FireMagic({this.onComplete});

  final void Function(FireMagic)? onComplete;

  @override
  Future<void> onLoad() async {
    size = Vector2(13, 16);

    final image = await gameRef.images.load('magic-fire.png');
    final spriteSheet = SpriteSheet(image: image, srcSize: size);
    animation = spriteSheet.createAnimation(row: 0, stepTime: 0.1);

    add(ProtoHitbox('fire',
        position: Vector2(0, 0), size: size, ignore: ['leg', 'body']));

    final path2 = Path()..addOval(const Rect.fromLTRB(-50, -50, 50, 50));
    add(MoveAlongPathEffect(
        path2,
        EffectController(
          duration: 15,
          // startDelay: i * 0.3,
          // infinite: true,
        ),
        oriented: false, onComplete: () {
      onComplete?.call(this);
      removeFromParent();
    }));
  }
}
