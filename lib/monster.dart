import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flame/sprite.dart';
import 'package:practice_flame/human1.dart';
import 'package:practice_flame/map_game.dart';

class Monster extends SpriteAnimationComponent
    with HasGameRef, CollisionCallbacks {
  Monster(this.human, {this.path});

  final double speed = 50;

  final Human human;

  final Queue<TileNode>? path;

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load('monster1.png');
    final spriteSheet = SpriteSheet(image: image, srcSize: Vector2(32, 32));

    animation = spriteSheet.createAnimation(
        row: 0, stepTime: 0.2, loop: true, from: 0, to: 5);
    size = Vector2(32, 32);
    // setOpacity(0.8);

    final hitboxPaint = BasicPalette.white.paint()
      ..style = PaintingStyle.stroke;
    add(
      RectangleHitbox(
        position: Vector2(0, 0),
        size: Vector2(32, 32),
      )
        ..paint = hitboxPaint
        ..renderShape = true,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (path != null) {
      if (path?.isNotEmpty ?? false) {
        final target = path!.first.position;
        position.moveToTarget(target, speed * dt);
        if (position.distanceTo(target) < 1) {
          path!.removeFirst();
        }
      }
      return;
    }

    final r =
        atan2(human.position.y - position.y, human.position.x - position.x);
    final deltaPosition = Vector2(cos(r) * (speed * dt), sin(r) * (speed * dt));
    position.add(deltaPosition);
  }
}
