import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:practice_flame/proto/character.dart';
import 'package:practice_flame/proto/direction.dart';
import 'package:practice_flame/proto/gem.dart';
import 'package:practice_flame/proto/info.dart';
import 'package:practice_flame/proto/magic.dart';
import 'package:practice_flame/proto/monster.dart';
import 'package:practice_flame/proto/weapon.dart';

class MainPlayer extends Character
    with KeyboardHandler, CharacterCollisionCallbacks {
  final String _imageFile = 'human2_outline.png';

  late final idle = <SpriteAnimation>[];
  late final move = <SpriteAnimation>[];

  late final CharacterHitbox bodyHitboxy;
  late final CharacterHitbox legHitbox;

  int point = 0;

  EightDirection _direction = EightDirection.down;

  final Vector2 velocity = Vector2.zero();

  Set<LogicalKeyboardKey>? _keysPressed;

  Map<int, Set<LogicalKeyboardKey>> _collisionMap = {};
  Map<int, CollisionInfo> _collisionMap2 = {};

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

    CollisionInfo collisionInfo = _collisionMap2.values.length == 0
        ? CollisionInfo()
        : _collisionMap2.values.reduce((value, element) => value..add(element));

    velocity.x = 0;
    velocity.y = 0;
    _keysPressed?.forEach((element) {
      final collision =
          _collisionMap.values.where((e) => e.contains(element)).isNotEmpty;

      if (element == LogicalKeyboardKey.keyW && !collisionInfo.up) {
        velocity.y += -1;
      } else if (element == LogicalKeyboardKey.keyA && !collisionInfo.left) {
        velocity.x += -1;
      } else if (element == LogicalKeyboardKey.keyS && !collisionInfo.down) {
        velocity.y += 1;
      } else if (element == LogicalKeyboardKey.keyD && !collisionInfo.right) {
        velocity.x += 1;
      }
    });

    if (_keysPressed?.contains(LogicalKeyboardKey.space) ?? false) {
      if (_weapon == null) {
        _weapon = ProtoWeapon(_direction, onComplete: () {
          Timer(Duration(milliseconds: gameInfo.playerInfo.attackInterval), () {
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

    final deltaPosition = velocity * (gameInfo.playerInfo.speed * dt);
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
      if (other is ProtoWeapon ||
          other is ProtoMagic ||
          other is CharacterHitbox ||
          other is ProtoGem ||
          other is ProtoMonster) return;

      Vector2 pos = Vector2.copy(position);
      pos.add(legHitbox.position);
      pos.add(Vector2(legHitbox.size.x / 2, legHitbox.size.y / 2));

      Vector2 pointsSum =
          intersectionPoints.reduce((value, element) => value..add(element));
      pointsSum.divide(Vector2.all(intersectionPoints.length.toDouble()));

      double a = atan2(pointsSum.y - pos.y, pointsSum.x - pos.x);

      _showHit(pos);
      _showHit(pointsSum);

      _collisionMap2[other.hashCode] = CollisionInfo.fromEightDirection(
          EightDirectionExtension.fromRadians(a));

      _collisionMap[other.hashCode] = <LogicalKeyboardKey>{};
      _keysPressed?.forEach((element) {
        _collisionMap[other.hashCode]?.add(element);
      });
    }
    if (own == bodyHitboxy) {
      if (other is ProtoGem) {
        other.removeFromParent();
        point++;
      }
    }
  }

  @override
  void onCollisionEnd(CharacterHitbox own, PositionComponent other) {
    if (own == legHitbox) {
      if (other is ProtoWeapon) return;
      _collisionMap.remove(other.hashCode);
      _collisionMap2.remove(other.hashCode);
    }
  }

  void _showHit(Vector2 pos) {
    gameRef.add(
      ParticleSystemComponent(
        priority: 1000,
        position: pos,
        particle: Particle.generate(
          count: 1,
          lifespan: 3,
          generator: (i) {
            return CircleParticle(
              radius: 1,
              paint: Paint()..color = Colors.white,
            );
          },
        ),
      ),
    );
  }
}

class CollisionInfo {
  CollisionInfo({
    this.up = false,
    this.right = false,
    this.down = false,
    this.left = false,
  });
  factory CollisionInfo.fromEightDirection(EightDirection direction) {
    switch (direction) {
      case EightDirection.up:
        return CollisionInfo(up: true);
      case EightDirection.upRight:
        return CollisionInfo(up: true, right: true);
      case EightDirection.right:
        return CollisionInfo(right: true);
      case EightDirection.downRight:
        return CollisionInfo(right: true, down: true);
      case EightDirection.down:
        return CollisionInfo(down: true);
      case EightDirection.downLeft:
        return CollisionInfo(left: true, down: true);
      case EightDirection.left:
        return CollisionInfo(left: true);
      case EightDirection.upLeft:
        return CollisionInfo(up: true, left: true);
    }
    return CollisionInfo();
  }
  bool up;
  bool right;
  bool down;
  bool left;

  void add(CollisionInfo other) {
    if (other.up) up = true;
    if (other.right) right = true;
    if (other.down) down = true;
    if (other.left) left = true;
  }
}
