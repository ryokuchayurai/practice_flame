import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:practice_flame/proto/character.dart';
import 'package:practice_flame/proto/direction.dart';
import 'package:practice_flame/proto/magic.dart';
import 'package:practice_flame/proto/monster.dart';
import 'package:practice_flame/proto/proto_layer.dart';

class Heroine extends Character with ComponentRef {
  final String _imageFile = 'human3_outline.png';

  final idle = <SpriteAnimation>[];
  final move = <SpriteAnimation>[];
  final action = <SpriteAnimation>[];

  final cast = <SpriteAnimation>[];

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

    animation = idle[EightDirection.down.spriteIndex];
  }

  Timer? _castTimer;

  @override
  void update(double dt) {
    super.update(dt);

    final monster =
        getRef<MainLayerComponent>().getNearMonster(position, range: 500);
    if (monster != null && _castTimer == null) {
      startCast(monster);
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

    Timer(Duration(milliseconds: 200), () {
      _castTimer?.cancel();
      animation = cast[1];

      final from = position.clone()..add(Vector2(size.x / 2, 0));

      getRef<MainLayerComponent>()
          .add(ProtoMagic(position: from, target: monster.position));

      Timer(Duration(milliseconds: 100), () {
        animation = idle[EightDirection.down.spriteIndex];
        _castTimer = null;
      });
    });
  }
}
