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

  final cast = <SpriteAnimation>[];

  final _fires = <FireMagic>[];

  @override
  Future<void> onLoad() async {
    super.onLoad();

    size = Vector2(16, 32);

    final image = await gameRef.images.load(_imageFile);
    final spriteSheet = SpriteSheet(image: image, srcSize: size);

    idle.addAll(create4DirectionAnimation(spriteSheet, 0.2, 0, 1));
    move.addAll(create4DirectionAnimation(spriteSheet, 0.2, 1, 5));
    action.addAll(create4DirectionAnimation(spriteSheet, 0.2, 5, 7));

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

    final monster =
        getRef<MainLayerComponent>().getNearMonster(position, range: 300);
    if (monster != null && _castTimer == null) {
      startCast(monster);
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
  }

  void startCast(ProtoMonster monster) {
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

      final from = position.clone()..add(Vector2(size.x / 2, 0));

      getRef<MainLayerComponent>()
          .add(ProtoMagic(position: from, target: monster.position));

      if (_fires.length < 1) {
        _fires.add(FireMagic(onComplete: (fire) => _fires.remove(fire))..position = position);
        getRef<MainLayerComponent>().add(_fires.last);
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
    if (other is ProtoMonster && !hasDamage) {
      gameInfo.heroineInfo.hp--;
      effectDamage(repeatCount: 10);
      if (gameInfo.heroineInfo.hp <= 0) {
        gameStatus.mode = GameMode.gameOver;
      }
    }
  }

  @override
  void onCollisionEnd(CharacterHitbox own, PositionComponent other) {}
}
