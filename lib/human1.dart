import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:practice_flame/bat.dart';
import 'package:practice_flame/gem.dart';
import 'package:practice_flame/magic_effect.dart';
import 'package:practice_flame/map_game.dart';
import 'package:practice_flame/monster.dart';
import 'package:win32_gamepad/win32_gamepad.dart';

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
  int get spriteIndex => [3, 3, 3, 1, 0, 0, 0, 2][index];
}

class Human extends SpriteAnimationComponent
    with HasGameRef, KeyboardHandler, CollisionCallbacks {
  final String _imageFile = 'human2_outline.png';
  final Vector2 _size = Vector2(16, 32);

  final double speed = 100;

  late final idle = <SpriteAnimation>[];
  late final move = <SpriteAnimation>[];
  late final action = <SpriteAnimation>[];

  final Vector2 velocity = Vector2.zero();

  Direction _direction = Direction.down;
  bool _action = false;
  Set<LogicalKeyboardKey>? _keysPressed;
  Map<int, Set<LogicalKeyboardKey>> _collisionMap = {};

  int gem = 0;
  int hp = 10;

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load(_imageFile);
    final spriteSheet = SpriteSheet(image: image, srcSize: _size);

    idle.addAll(_create4DirectionAnimation(spriteSheet, 0.2, 0, 1));
    move.addAll(_create4DirectionAnimation(spriteSheet, 0.2, 1, 5));
    action.addAll(_create4DirectionAnimation(spriteSheet, 0.2, 5, 6));

    animation = idle[0];
    size = _size;

    final hitboxPaint = BasicPalette.white.paint()
      ..style = PaintingStyle.stroke;
    add(
      RectangleHitbox(
        position: Vector2(0, 24),
        size: Vector2(16, 8),
      )
        ..paint = hitboxPaint
        ..renderShape = true,
    );

    // add(CircleComponent(
    //     radius: 32,
    //     position: Vector2(-24, -12),
    //     paint: Paint()
    //       ..color = Colors.lightBlue.withOpacity(0.6)
    //       ..blendMode = BlendMode.plus));
  }

  List<SpriteAnimation> _create4DirectionAnimation(
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

  void onGamepadEvent(GamepadState state) {
    final leftstick = Vector2(
        state.leftThumbstickX.toDouble(), state.leftThumbstickY.toDouble());
    final keysPressed = <LogicalKeyboardKey>[];
    if (leftstick.x > 32767 * 0.5) {
      keysPressed.add(LogicalKeyboardKey.keyD);
    }
    if (leftstick.x < -32767 * 0.5) {
      keysPressed.add(LogicalKeyboardKey.keyA);
    }
    if (leftstick.y > 32767 * 0.5) {
      keysPressed.add(LogicalKeyboardKey.keyW);
    }
    if (leftstick.y < -32767 * 0.5) {
      keysPressed.add(LogicalKeyboardKey.keyS);
    }

    _keysPressed = keysPressed.toSet();

    if (state.buttonA) {
      final bat = Bat(_direction, onComplete: (b) => remove(b));
      add(bat);
    }
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keysPressed = keysPressed;
    final isKeyDown = event is RawKeyDownEvent;
    if (event.logicalKey == LogicalKeyboardKey.space && isKeyDown) {
      final bat = Bat(_direction, onComplete: (b) => remove(b));
      add(bat);
    }
    return super.onKeyEvent(event, keysPressed);
    // final isKeyDown = event is RawKeyDownEvent;
    //
    // final bool handled;
    // if (event.logicalKey == LogicalKeyboardKey.keyA) {
    //   velocity.x = isKeyDown ? -1 : 0;
    //   handled = true;
    // } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
    //   velocity.x = isKeyDown ? 1 : 0;
    //   handled = true;
    // } else if (event.logicalKey == LogicalKeyboardKey.keyW) {
    //   velocity.y = isKeyDown ? -1 : 0;
    //   handled = true;
    // } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
    //   velocity.y = isKeyDown ? 1 : 0;
    //   handled = true;
    // } else if (event.logicalKey == LogicalKeyboardKey.space) {
    //   velocity.x = 0;
    //   velocity.y = 0;
    //   _action = isKeyDown;
    //   if (isKeyDown) {
    //     _startMagicEffect();
    //   } else {
    //     _stopMagicEffect();
    //   }
    //   handled = true;
    // } else {
    //   handled = false;
    // }
    //
    // if (handled) {
    //   if (velocity.isZero()) {
    //     animation = _action ? action[_direction.spriteIndex]: idle[_direction.spriteIndex];
    //     if (_action) {
    //
    //     }
    //   } else {
    //     _direction = getDirection();
    //     animation = move[_direction.spriteIndex];
    //   }
    //
    //   return false;
    // } else {
    //   return super.onKeyEvent(event, keysPressed);
    // }
  }

  @override
  void update(double dt) {
    super.update(dt);

    velocity.x = 0;
    velocity.y = 0;
    _keysPressed?.forEach((element) {
      // final collision = _collisionKeysPressed.contains(element);
      final collision =
          _collisionMap.values.where((e) => e.contains(element)).isNotEmpty;

      if (element == LogicalKeyboardKey.keyW && !collision) {
        velocity.y += -1;
      } else if (element == LogicalKeyboardKey.keyA && !collision) {
        velocity.x += -1;
      } else if (element == LogicalKeyboardKey.keyS && !collision) {
        velocity.y += 1;
      } else if (element == LogicalKeyboardKey.keyD && !collision) {
        velocity.x += 1;
      }
    });

    if (velocity.isZero()) {
      animation = _action
          ? action[_direction.spriteIndex]
          : idle[_direction.spriteIndex];
    } else {
      _direction = getDirection();
      animation = move[_direction.spriteIndex];
    }

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

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Bat) return;

    if (other is Gem) {
      gem++;
      (gameRef as MapGame).gempoint.text = '$gemポイント';
      other.removeFromParent();
      return;
    }

    intersectionPoints.forEach((element) {
      _test(element);
    });

    if (other is Monster) {
      hp--;
      (gameRef as MapGame).hitpoint.text = '$hp';
      (gameRef as MapGame).test();

      add(ColorEffect(
          Colors.white,
          const Offset(0, 1),
          EffectController(
              duration: 0.1, reverseDuration: 0.1, repeatCount: 10)));
      return;
    }

    _collisionMap[other.hashCode] = <LogicalKeyboardKey>{};
    _keysPressed?.forEach((element) {
      _collisionMap[other.hashCode]?.add(element);
    });
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    _collisionMap.remove(other.hashCode);
  }

  void _test(Vector2 pos) {
    gameRef.add(
      ParticleSystemComponent(
        priority: 1000,
        position: pos,
        particle: Particle.generate(
          count: 1,
          lifespan: 3,
          generator: (i) {
            return MovingParticle(
                from: Vector2.zero(),
                to: Vector2.zero(),
                child: CircleParticle(
                  radius: 1,
                  paint: Paint()..color = Colors.white,
                ));
          },
        ),
      ),
    );
  }
}
