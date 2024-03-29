import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:practice_flame/proto/bubble.dart';
import 'package:practice_flame/proto/character.dart';
import 'package:practice_flame/proto/direction.dart';
import 'package:practice_flame/proto/gem.dart';
import 'package:practice_flame/proto/heroine.dart';
import 'package:practice_flame/proto/info.dart';
import 'package:practice_flame/proto/magic.dart';
import 'package:practice_flame/proto/monster.dart';
import 'package:practice_flame/proto/proto_game.dart';
import 'package:practice_flame/proto/proto_layer.dart';
import 'package:practice_flame/proto/status.dart';
import 'package:practice_flame/proto/weapon.dart';

class MainPlayer extends Character
    with KeyboardHandler, CharacterCollisionCallbacks, ComponentRef {
  final String _imageFile = 'human2_outline.png';

  late final idle = <SpriteAnimation>[];
  late final move = <SpriteAnimation>[];

  final idleFollow = <SpriteAnimation>[];
  final moveFollow = <SpriteAnimation>[];

  late final CharacterHitbox bodyHitboxy;
  late final CharacterHitbox legHitbox;

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

    idleFollow
        .addAll(create4DirectionAnimation(spriteSheet, 0.2, 0, 1, rowStart: 4));
    moveFollow
        .addAll(create4DirectionAnimation(spriteSheet, 0.2, 1, 5, rowStart: 4));

    animation = idle[EightDirection.down.spriteIndex];

    add(bodyHitboxy = CharacterHitbox('body', size: size));

    add(legHitbox = CharacterHitbox(
      'leg',
      position: Vector2(0, 28),
      size: Vector2(16, 8),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_path.isNotEmpty) {
      final r = atan2(_path.first.y - position.y, _path.first.x - position.x);
      final direction = EightDirectionExtension.fromRadians(r);
      animation = move[direction.spriteIndex];

      position.moveToTarget(_path.first, gameInfo.playerInfo.speed * dt);
      if (position.distanceTo(_path.first) < 1) {
        _path.removeFirst();
        if (_path.isEmpty) {
          // TODO callback of movePath
        }
      }
      return;
    }

    if (gameStatus.mode != GameMode.main) return;

    CollisionInfo collisionInfo = _collisionMap2.values.length == 0
        ? CollisionInfo()
        : _collisionMap2.values.reduce((value, element) => value..add(element));

    velocity.x = 0;
    velocity.y = 0;
    _keysPressed?.forEach((element) {
      final collision =
          _collisionMap.values.where((e) => e.contains(element)).isNotEmpty;

      if ((element == LogicalKeyboardKey.keyW ||
              element == LogicalKeyboardKey.arrowUp) &&
          !collisionInfo.up) {
        velocity.y += -1;
      } else if ((element == LogicalKeyboardKey.keyA ||
              element == LogicalKeyboardKey.arrowLeft) &&
          !collisionInfo.left) {
        velocity.x += -1;
      } else if ((element == LogicalKeyboardKey.keyS ||
              element == LogicalKeyboardKey.arrowDown) &&
          !collisionInfo.down) {
        velocity.y += 1;
      } else if ((element == LogicalKeyboardKey.keyD ||
              element == LogicalKeyboardKey.arrowRight) &&
          !collisionInfo.right) {
        velocity.x += 1;
      }
    });

    if (_keysPressed?.contains(LogicalKeyboardKey.space) ?? false) {
      if (_weapon == null) {
        _weapon = ProtoWeapon(_direction, onComplete: () {
          _weapon = null;
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

    final heroine =
        parent?.children.firstWhere((value) => value is Heroine) as Heroine;
    if (_keysPressed?.contains(LogicalKeyboardKey.keyC) ?? false) {
      if (heroine.position.distanceTo(position).abs() < 40) {
        if (velocity.isZero()) {
          animation = idleFollow[_direction.spriteIndex];
        } else {
          animation = moveFollow[_direction.spriteIndex];
        }
        heroine.follow(_direction, position, velocity.isZero());
      }
    } else {
      heroine.unfollow();
    }

    final deltaPosition = velocity * (gameInfo.playerInfo.speed * dt);
    position.add(deltaPosition);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keysPressed = keysPressed;

    if (event is RawKeyUpEvent &&
        event.logicalKey == LogicalKeyboardKey.digit0) {
      // add(Bubble('親譲りの無鉄砲で小供の時から損ばかりしている。小学校に居る時分学校の二階から飛び降りて一週間ほど腰を抜かした事がある。',
      //     sound: 'talk_1'));
      speak('親譲りの無鉄砲で小供の時から損ばかりしている。小学校に居る時分学校の二階から飛び降りて一週間ほど腰を抜かした事がある。');
    } else if (event is RawKeyUpEvent &&
        event.logicalKey == LogicalKeyboardKey.digit9) {
      final path = Queue<Vector2>();
      path.add(Vector2(100, 100));
      path.add(Vector2(200, 300));
      movePath(path);
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(CharacterHitbox own, Set<Vector2> intersectionPoints,
      PositionComponent other) {
    if (own == legHitbox) {
      if (other is ProtoWeapon ||
          other is ArrowMagic ||
          other is CharacterHitbox ||
          other is ProtoGem ||
          other is Enemy ||
          other is FireMagic ||
          other is ThunderMagic) return;

      Vector2 pos = Vector2.copy(position);
      pos.add(legHitbox.position);
      pos.add(Vector2(legHitbox.size.x / 2, legHitbox.size.y / 2));

      Vector2 pointsSum =
          intersectionPoints.reduce((value, element) => value..add(element));
      pointsSum.divide(Vector2.all(intersectionPoints.length.toDouble()));

      double a = atan2(pointsSum.y - pos.y, pointsSum.x - pos.x);

      (gameRef as ProtoGame).showPoint(pos);
      (gameRef as ProtoGame).showPoint(pointsSum);

      pointsSum.sub(pos);
      pointsSum.divide(Vector2(8, 8));
      position.sub(pointsSum);

      _collisionMap2[other.hashCode] = CollisionInfo.fromEightDirection(
          EightDirectionExtension.fromRadians(a));

      _collisionMap[other.hashCode] = <LogicalKeyboardKey>{};
      _keysPressed?.forEach((element) {
        _collisionMap[other.hashCode]?.add(element);
      });
    }
    if (own == bodyHitboxy) {
      if (other is ProtoGem) {
        gameInfo.playerInfo.point += other.exp;
        other.removeFromParent();
      } else if (other is Enemy && !hasDamage) {
        gameInfo.playerInfo.hp -= other.attack;
        effectDamage(repeatCount: 10);
        if (gameInfo.playerInfo.hp <= 0) {
          gameStatus.mode = GameMode.gameOver;
        }
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

  Queue<Vector2> _path = Queue();

  void movePath(Queue<Vector2> path) {
    _path.addAll(path);
  }

  void speak(String text) {
    add(Bubble(text, sound: 'talk_1', closeDuration: Duration(seconds: 2)));
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
