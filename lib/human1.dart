import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:practice_flame/magic_effect.dart';

enum Direction {
  up,
  upLeft,
  upRight,
  right,
  down,
  downRight,
  downLeft,
  left,
}

extension DirectionExtension on Direction {
  // static Direction createDegree(double d) {
  //   if(d)
  // }
  int get spriteIndex => [3,3,3,1,0,0,0,2][index];
}


class Human extends SpriteAnimationComponent with HasGameRef, KeyboardHandler, CollisionCallbacks {

  final String _imageFile = 'human2_outline.png';
  final Vector2 _size = Vector2(16, 32);

  final double speed = 100;

  late final idle = <SpriteAnimation>[];
  late final move = <SpriteAnimation>[];
  late final action = <SpriteAnimation>[];

  final Vector2 velocity = Vector2.zero();

  Direction _direction = Direction.down;
  bool _action = false;

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load(_imageFile);
    final spriteSheet = SpriteSheet(image: image, srcSize: _size);

    idle.addAll(_create4DirectionAnimation(spriteSheet, 0.2, 0, 1));
    move.addAll(_create4DirectionAnimation(spriteSheet, 0.2, 1, 5));
    action.addAll(_create4DirectionAnimation(spriteSheet, 0.2, 5, 6));

    animation = idle[0];
    size = _size;

    debugPrint('prio===${priority}');
  }

  List<SpriteAnimation> _create4DirectionAnimation(SpriteSheet sheet, double stepTime, int from, int to) {
    return [
      sheet.createAnimation(row: 0, stepTime: stepTime, loop: true, from: from, to: to),
      sheet.createAnimation(row: 1, stepTime: stepTime, loop: true, from: from, to: to),
      sheet.createAnimation(row: 2, stepTime: stepTime, loop: true, from: from, to: to),
      sheet.createAnimation(row: 3, stepTime: stepTime, loop: true, from: from, to: to),
    ];
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is RawKeyDownEvent;

    final bool handled;
    if (event.logicalKey == LogicalKeyboardKey.keyA) {
      velocity.x = isKeyDown ? -1 : 0;
      handled = true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
      velocity.x = isKeyDown ? 1 : 0;
      handled = true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyW) {
      velocity.y = isKeyDown ? -1 : 0;
      handled = true;
    } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
      velocity.y = isKeyDown ? 1 : 0;
      handled = true;
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      velocity.x = 0;
      velocity.y = 0;
      _action = isKeyDown;
      if (isKeyDown) {
        _startMagicEffect();
      } else {
        _stopMagicEffect();
      }
      handled = true;
    } else {
      handled = false;
    }

    if (handled) {
      if (velocity.isZero()) {
        animation = _action ? action[_direction.spriteIndex]: idle[_direction.spriteIndex];
        if (_action) {

        }
      } else {
        _direction = getDirection();
        animation = move[_direction.spriteIndex];
      }

      return false;
    } else {
      return super.onKeyEvent(event, keysPressed);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final deltaPosition = velocity * (speed * dt);
    position.add(deltaPosition);
  }

  Direction getDirection() {
    final d = velocity.angleToSigned(Vector2(0, 1)) * radians2Degrees;
    if (d > -22.5 && d <= 22.5) {
      return Direction.down;
    } else if (d > -67.5 && d <= -22.5) {
      return Direction.downLeft;
    } else if (d > -112.5 && d <= -67.5) {
      return Direction.left;
    } else if (d > -157.5 && d <= -112.5) {
      return Direction.upLeft;
    } else if ((d > -180 && d <= -157.5) || (d > 157.5 && d <= 180)) {
      return Direction.up;
    } else if (d > 112.5 && d <= 157.5) {
      return Direction.upRight;
    } else if (d > 67.5 && d <= 112.5) {
      return Direction.right;
    } else {
      return Direction.downRight;
    }
  }

  MagicEffect? _magicEffect;

  void _startMagicEffect() {
    if (_magicEffect != null) return;
    add(_magicEffect = MagicEffect(_direction));
  }

  void _stopMagicEffect() {
    if (_magicEffect == null) return;
    remove(_magicEffect!);
    _magicEffect = null;
  }

  @override
  void renderTree(Canvas canvas) {
    canvas.save();
    canvas.transform(transformMatrix.storage);

    children.where((element) => element.priority < 0).forEach((c) => c.renderTree(canvas));
    render(canvas);
    children.where((element) => element.priority >= 0).forEach((c) => c.renderTree(canvas));
    if (debugMode) {
      renderDebugMode(canvas);
    }

    canvas.restore();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints,
      PositionComponent other,
      ) {
    super.onCollisionStart(intersectionPoints, other);
    velocity.negate();
  }
}