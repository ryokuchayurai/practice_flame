import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:practice_flame/human1.dart';

class Monster extends SpriteAnimationComponent with HasGameRef, CollisionCallbacks {

  Monster(this.human);

  final double speed = 20;

  final Human human;

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load('monster1.png');
    final spriteSheet = SpriteSheet(image: image, srcSize: Vector2(32,32));

    animation = spriteSheet.createAnimation(row: 0, stepTime: 0.2, loop: true, from: 0, to: 5);
    size = Vector2(32, 32);
    // setOpacity(0.8);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final r = atan2(human.position.y - position.y, human.position.x - position.x);
    final deltaPosition = Vector2(cos(r)* (speed * dt), sin(r)* (speed * dt));
    position.add(deltaPosition);
  }

}