import 'dart:async';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:practice_flame/proto/character.dart';
import 'package:practice_flame/proto/direction.dart';
import 'package:practice_flame/proto/weapon.dart';

class MainPlayer extends Character
    with KeyboardHandler, CharacterCollisionCallbacks {
  final String _imageFile = 'human2_outline.png';

  late final idle = <SpriteAnimation>[];
  late final move = <SpriteAnimation>[];

  late final CharacterHitbox bodyHitboxy;
  late final CharacterHitbox legHitbox;

  double speed = 60;

  EightDirection _direction = EightDirection.down;

  final Vector2 velocity = Vector2.zero();

  Set<LogicalKeyboardKey>? _keysPressed;

  Map<int, Set<LogicalKeyboardKey>> _collisionMap = {};

  ProtoWeapon? _weapon;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    size = Vector2(16, 32);
    scale = Vector2(1, 1);

    final image = await gameRef.images.load(_imageFile);
    final spriteSheet = SpriteSheet(image: image, srcSize: size);

    idle.addAll(create4DirectionAnimation(spriteSheet, 0.2, 0, 1));
    move.addAll(create4DirectionAnimation(spriteSheet, 0.2, 1, 5));

    animation = idle[EightDirection.down.spriteIndex];

    add(bodyHitboxy = CharacterHitbox(size: size));

    add(legHitbox = CharacterHitbox(
      position: Vector2(0, 24),
      size: Vector2(16, 8),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    velocity.x = 0;
    velocity.y = 0;
    _keysPressed?.forEach((element) {
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

    if (_keysPressed?.contains(LogicalKeyboardKey.space) ?? false) {
      if (_weapon == null) {
        _weapon = ProtoWeapon(_direction, onComplete: () {
          Timer(Duration(milliseconds: 500), () {
            _weapon = null;
          });
        });
        add(_weapon!);
      }
    }

    if (velocity.isZero()) {
      animation = idle[_direction.spriteIndex];
    } else {
      _direction = EightDirectionExtension.fromVector2(velocity);
      animation = move[_direction.spriteIndex];
    }

    final deltaPosition = velocity * (speed * dt);
    position.add(deltaPosition);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keysPressed = keysPressed;
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(CharacterHitbox own, Set<Vector2> intersectionPoints,
      PositionComponent other) {
    if (own == legHitbox) {
      if (other is ProtoWeapon) return;
      _collisionMap[other.hashCode] = <LogicalKeyboardKey>{};
      _keysPressed?.forEach((element) {
        _collisionMap[other.hashCode]?.add(element);
      });
    }
  }

  @override
  void onCollisionEnd(CharacterHitbox own, PositionComponent other) {
    if (own == legHitbox) {
      if (other is ProtoWeapon) return;
      _collisionMap.remove(other.hashCode);
    }
  }
}
