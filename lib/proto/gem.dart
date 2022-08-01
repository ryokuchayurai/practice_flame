import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flame/sprite.dart';
import 'package:practice_flame/proto/hitbox.dart';

class ProtoGem extends SpriteAnimationComponent
    with HasGameRef, CollisionCallbacks {
  ProtoGem(this.exp);

  final int exp;

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load('gem.png');
    final spriteSheet = SpriteSheet(image: image, srcSize: Vector2(5, 9));

    animation = spriteSheet.createAnimation(
        row: 0, stepTime: 0.2, loop: true, from: 0, to: 3);
    size = Vector2(5, 9);

    final hitboxPaint = BasicPalette.white.paint()
      ..style = PaintingStyle.stroke;
    add(
      ProtoHitbox(
        'gem',
        position: Vector2(0, 0),
        size: Vector2(5, 9),
        ignore: ['monster'],
      )
        ..paint = hitboxPaint
        ..renderShape = false,
    );
  }
}
