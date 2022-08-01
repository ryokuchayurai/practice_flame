import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:practice_flame/proto/character.dart';
import 'package:practice_flame/proto/direction.dart';
import 'package:practice_flame/proto/info.dart';
import 'package:practice_flame/proto/magic.dart';
import 'package:practice_flame/proto/main_player.dart';
import 'package:practice_flame/proto/monster.dart';
import 'package:practice_flame/proto/proto_layer.dart';
import 'package:practice_flame/proto/status.dart';

class Heroine extends Character with ComponentRef, CharacterCollisionCallbacks {
  final String _imageFile = 'human3_outline.png';

  final idle = <SpriteAnimation>[];
  final move = <SpriteAnimation>[];
  final action = <SpriteAnimation>[];

  final idleFollow = <SpriteAnimation>[];
  final moveFollow = <SpriteAnimation>[];

  final cast = <SpriteAnimation>[];

  final _fires = <FireMagic>[];

  bool _follow = false;

  Vector2? _target;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    size = Vector2(16, 32);

    final image = await gameRef.images.load(_imageFile);
    final spriteSheet = SpriteSheet(image: image, srcSize: size);

    idle.addAll(create4DirectionAnimation(spriteSheet, 0.2, 0, 1));
    move.addAll(create4DirectionAnimation(spriteSheet, 0.2, 1, 5));
    action.addAll(create4DirectionAnimation(spriteSheet, 0.2, 5, 7));

    idleFollow
        .addAll(create4DirectionAnimation(spriteSheet, 0.2, 0, 1, rowStart: 4));
    moveFollow
        .addAll(create4DirectionAnimation(spriteSheet, 0.2, 1, 5, rowStart: 4));

    cast.add(spriteSheet.createAnimation(
        row: 0, stepTime: 0.1, loop: true, from: 5, to: 6));
    cast.add(spriteSheet.createAnimation(
        row: 0, stepTime: 0.1, loop: true, from: 6, to: 7));

    add(CharacterHitbox('heroine_body', size: size));

    animation = idle[EightDirection.down.spriteIndex];
  }

  Timer? _castTimer;

  @override
  void update(double dt) {
    super.update(dt);

    final enemy =
        getRef<MainLayerComponent>().getNearEnemy(position, range: 300);
    if (enemy != null && _castTimer == null && !_follow) {
      startCast(enemy);
    }

    final mp = parent?.children.firstWhere((value) => value is MainPlayer)
        as MainPlayer;
    if (mp.position.distanceTo(position).abs() < 40) {
      int needPoint =
          (gameInfo.heroineInfo.level * gameInfo.heroineInfo.level * 5 / 2)
              .ceil();
      if (gameInfo.playerInfo.point >= needPoint) {
        gameInfo.playerInfo.point -= needPoint;
        gameInfo.heroineInfo.point += needPoint;
        gameInfo.heroineInfo.level++;

        gameStatus.mode = GameMode.levelUp;
      }
    }

    if (_target != null) {
      position.moveToTarget(_target!, 100 * dt);
    }
  }

  void startCast(Enemy enemy) {
    animation = cast[0];

    final random = Random();
    _castTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      add(ParticleSystemComponent(
          position: Vector2(8, 36),
          particle: Particle.generate(
            lifespan: 1.5,
            count: 10,
            generator: (i) => MovingParticle(
                curve: Curves.easeInCubic,
                from: Vector2(random.nextInt(30) - 15, 0),
                to: Vector2(random.nextInt(30) - 15,
                    -30 - random.nextInt(20).toDouble()),
                child: CircleParticle(
                  radius: 1,
                  paint: Paint()..color = Colors.white.withOpacity(0.6),
                )),
          )));
    });

    Timer(Duration(milliseconds: gameInfo.heroineInfo.castTime), () {
      _castTimer?.cancel();
      animation = cast[1];

      final from = position.clone()..add(Vector2(size.x / 2, -5));

      getRef<MainLayerComponent>()
          .add(ArrowMagic(position: from, target: enemy.position));

      if (_fires.length < 3) {
        _fires.add(FireMagic(onComplete: (fire) => _fires.remove(fire))
          ..position = position);
        getRef<MainLayerComponent>().add(_fires.last);
      }

      getRef<MainLayerComponent>().add(IceMagic(enemy));

      for (var i = 0; i < 5; i++) {
        getRef<MainLayerComponent>().add(ThunderMagic(from));
      }

      Timer(Duration(milliseconds: gameInfo.heroineInfo.castInterval), () {
        animation = idle[EightDirection.down.spriteIndex];
        _castTimer = null;
      });
    });
  }

  @override
  void onCollisionStart(CharacterHitbox own, Set<Vector2> intersectionPoints,
      PositionComponent other) {
    if (other is Enemy && !hasDamage) {
      gameInfo.heroineInfo.hp -= other.attack;
      effectDamage(repeatCount: 10);
      if (gameInfo.heroineInfo.hp <= 0) {
        gameStatus.mode = GameMode.gameOver;
      }
    }
  }

  @override
  void onCollisionEnd(CharacterHitbox own, PositionComponent other) {}

  void follow(EightDirection direction, Vector2 position, bool idle) {
    _target = position.clone();
    switch (direction) {
      case EightDirection.up:
      case EightDirection.upLeft:
      case EightDirection.upRight:
        _target?.add(Vector2(0, 14));
        break;
      case EightDirection.left:
        _target?.add(Vector2(14, 0));
        break;
      case EightDirection.right:
        _target?.add(Vector2(-14, 0));
        break;
      case EightDirection.down:
      case EightDirection.downLeft:
      case EightDirection.downRight:
        _target?.add(Vector2(0, -14));
        break;
    }

    if (idle) {
      animation = idleFollow[direction.spriteIndex];
    } else {
      animation = moveFollow[direction.spriteIndex];
    }
    _follow = true;
  }

  void unfollow() {
    _follow = false;
  }
}
